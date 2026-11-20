{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.openWebUI;
  stateRoot = "${config.home.homeDirectory}/.local/state/dotfiles/open-webui";
  runtimeRoot = "%t/dotfiles-open-webui";
  gatewaySocket = "${runtimeRoot}/gateway/socket";
  ingressSocket = "${runtimeRoot}/ingress/socket";

  image = pkgs.callPackage ../../packages/open-webui-image.nix { };
  imageName = "dotfiles/open-webui:${pkgs.open-webui.version}";

  podmanSetup = ''
    state=${lib.escapeShellArg stateRoot}
    runtime="''${XDG_RUNTIME_DIR:?}/dotfiles-open-webui"
    podman_args=(
      "--root=$state/podman"
      "--runroot=$runtime/podman"
      "--storage-driver=overlay"
      "--cgroup-manager=systemd"
    )
  '';

  preflight = pkgs.writeShellScript "dotfiles-open-webui-preflight" ''
    set -euo pipefail
    umask 077
    ${podmanSetup}

    for dir in "$state" "$state/data" "$state/podman" "$state/podman-config" "$runtime" "$runtime/ingress" "$runtime/gateway"; do
      if [[ -L "$dir" ]]; then
        echo "Open WebUI state/runtime path must not be a symlink: $dir" >&2
        exit 1
      fi
      ${pkgs.coreutils}/bin/install -d -m 0700 "$dir"
    done
    key="$state/data/.webui_secret_key"
    if [[ -e "$key" || -L "$key" ]]; then
      if [[ ! -f "$key" || -L "$key" || ! -s "$key" ]]; then
        echo "Invalid Open WebUI signing key" >&2
        exit 1
      fi
    else
      temp="$(${pkgs.coreutils}/bin/mktemp "$state/data/.webui_secret_key.XXXXXXXX")"
      trap '${pkgs.coreutils}/bin/rm -f -- "$temp"' EXIT
      ${pkgs.coreutils}/bin/head -c 24 /dev/urandom | ${pkgs.coreutils}/bin/base64 -w0 > "$temp"
      ${pkgs.coreutils}/bin/mv -n -- "$temp" "$key"
    fi
    [[ -s "$key" && ! -L "$key" && "$(${pkgs.coreutils}/bin/stat -c %a "$key")" == 600 ]]
    [[ -S "$runtime/gateway/socket" ]]

    [[ "$(${pkgs.podman}/bin/podman "''${podman_args[@]}" info --format '{{.Host.Security.Rootless}}')" == true ]]
    if [[ "$(${pkgs.podman}/bin/podman "''${podman_args[@]}" info --format '{{.Host.CgroupsVersion}}')" != "v2" ]]; then
      echo "Rootless Open WebUI requires cgroup v2 for enforced resource limits" >&2
      exit 1
    fi
    if [[ "$(${pkgs.podman}/bin/podman "''${podman_args[@]}" info --format '{{.Host.CgroupManager}}')" != "systemd" ]]; then
      echo "Rootless Open WebUI requires systemd-managed container cgroups" >&2
      exit 1
    fi
    ${pkgs.podman}/bin/podman "''${podman_args[@]}" rm --force --ignore dotfiles-open-webui >/dev/null
    ${pkgs.podman}/bin/podman "''${podman_args[@]}" load --input ${image}
  '';

  # All model and embedding inference belongs to Dubnium. Keep the container
  # offline; its sole application API target is the socket-mediated Supervisor.
  start = pkgs.writeShellScript "dotfiles-open-webui-run" ''
    set -euo pipefail
    ${podmanSetup}
    exec ${pkgs.podman}/bin/podman "''${podman_args[@]}" run \
      --rm --pull=never --name=dotfiles-open-webui \
      --network=none --cap-drop=ALL --security-opt=no-new-privileges \
      --read-only --cpus=2 --memory=2g --pids-limit=256 \
      --tmpfs=/tmp:rw,noexec,nosuid,nodev,size=256m \
      --volume="$state/data:/var/lib/open-webui:rw" \
      --volume="$runtime/ingress:/run/open-webui/ingress:rw" \
      --volume="$runtime/gateway:/run/open-webui/gateway:ro" \
      --env=WEBUI_URL=http://127.0.0.1:${toString cfg.port} \
      --env=WEBUI_AUTH=True \
      --env=ENABLE_PERSISTENT_CONFIG=False \
      --env=ENABLE_SIGNUP=${if cfg.bootstrapSignup then "True" else "False"} \
      --env=ENABLE_OPENAI_API=True \
      --env=OPENAI_API_BASE_URL=http://127.0.0.1:8080/v1 \
      --env=OPENAI_API_BASE_URLS=http://127.0.0.1:8080/v1 \
      --env=OPENAI_API_KEY=unused-local-gateway-key \
      --env=DEFAULT_MODELS=supervisor \
      --env=OFFLINE_MODE=True \
      --env=HF_HUB_OFFLINE=1 \
      --env=RAG_EMBEDDING_MODEL_AUTO_UPDATE=False \
      --env=RAG_RERANKING_MODEL_AUTO_UPDATE=False \
      --env=WHISPER_MODEL_AUTO_UPDATE=False \
      --env=RAG_EMBEDDING_MODEL_TRUST_REMOTE_CODE=False \
      --env=RAG_RERANKING_MODEL_TRUST_REMOTE_CODE=False \
      --env=BYPASS_EMBEDDING_AND_RETRIEVAL=True \
      --env=AUDIO_STT_ENGINE=web \
      --env=ENABLE_OLLAMA_API=False \
      --env=ENABLE_DIRECT_CONNECTIONS=False \
      --env=TOOL_SERVER_CONNECTIONS=[] \
      --env=TERMINAL_SERVER_CONNECTIONS=[] \
      --env=ENABLE_COMMUNITY_SHARING=False \
      --env=ENABLE_VERSION_UPDATE_CHECK=False \
      --env=ENABLE_CODE_EXECUTION=False \
      --env=ENABLE_CODE_INTERPRETER=False \
      --env=ENABLE_PLUGINS=False \
      --env=ENABLE_API_KEYS=False \
      --env=SCARF_NO_ANALYTICS=True \
      --env=DO_NOT_TRACK=True \
      --env=ANONYMIZED_TELEMETRY=False \
      ${lib.escapeShellArg imageName}
  '';

  # ExecStartPost participates in systemd ordering: the browser ingress
  # proxy does not start until Open WebUI responds on its private socket.
  readiness = pkgs.writeShellScript "dotfiles-open-webui-readiness" ''
    set -euo pipefail
    runtime="''${XDG_RUNTIME_DIR:?}/dotfiles-open-webui"
    for attempt in $(${pkgs.coreutils}/bin/seq 1 120); do
      if ${pkgs.curl}/bin/curl --fail --silent --max-time 2 \
        --unix-socket "$runtime/ingress/socket" \
        http://localhost/health >/dev/null; then
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 1
    done
    echo "Open WebUI did not become ready on its private ingress socket" >&2
    exit 1
  '';
  stop = pkgs.writeShellScript "dotfiles-open-webui-stop" ''
    set -euo pipefail
    ${podmanSetup}
    exec ${pkgs.podman}/bin/podman "''${podman_args[@]}" stop --time=30 --ignore dotfiles-open-webui
  '';
in
{
  options.dotfiles.openWebUI = {
    enable = lib.mkEnableOption "isolated local Open WebUI Podman user service";

    bootstrapSignup = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Temporarily permit first-admin registration on localhost; disable immediately after bootstrap.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Localhost-only HTTP browser port; must not overlap with Dubnium's NixOS Open WebUI service.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.dotfiles.host.userSystemd.enable;
        message = "dotfiles.openWebUI requires user systemd.";
      }
      {
        assertion = cfg.port != 8080 && cfg.port != 8081;
        message = "Open WebUI browser port must not collide with its internal Supervisor proxy.";
      }
    ];

    # Lazy frontend admission: browser socket starts the container through the
    # ingress proxy. Container model traffic is confined to the gateway socket.
    systemd.user.sockets.dotfiles-open-webui-ingress = {
      Unit.Description = "Loopback browser socket for isolated Open WebUI";
      Socket.ListenStream = "127.0.0.1:${toString cfg.port}";
      Install.WantedBy = [ "sockets.target" ];
    };
    systemd.user.services.dotfiles-open-webui-ingress = {
      Unit = {
        Description = "Open WebUI browser socket proxy";
        After = [ "dotfiles-open-webui.service" ];
        Requires = [ "dotfiles-open-webui.service" ];
      };
      Service = {
        ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd ${ingressSocket}";
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        # /run/user is otherwise hidden by ProtectHome; re-expose only
        # the ingress directory needed by systemd-socket-proxyd.
        ProtectHome = "tmpfs";
        BindReadOnlyPaths = [ "${runtimeRoot}/ingress" ];
        ProtectSystem = "strict";
        CapabilityBoundingSet = "";
        RestrictAddressFamilies = [ "AF_UNIX" ];
      };
    };

    systemd.user.sockets.dotfiles-open-webui-gateway = {
      Unit.Description = "Private Supervisor-only Open WebUI gateway socket";
      Socket = {
        ListenStream = gatewaySocket;
        DirectoryMode = "0700";
        SocketMode = "0600";
      };
      Install.WantedBy = [ "sockets.target" ];
    };
    systemd.user.services.dotfiles-open-webui-gateway = {
      Unit.Description = "Open WebUI exclusive Supervisor Gateway proxy";
      Service = {
        ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:8080";
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        CapabilityBoundingSet = "";
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
        ];
      };
    };

    systemd.user.services.dotfiles-open-webui = {
      Unit = {
        Description = "Rootless networkless Open WebUI";
        After = [ "dotfiles-open-webui-gateway.socket" ];
        Requires = [ "dotfiles-open-webui-gateway.socket" ];
        StartLimitIntervalSec = 300;
        StartLimitBurst = 5;
      };
      Service = {
        Type = "simple";
        Delegate = true;
        ExecStartPre = "${preflight}";
        ExecStart = "${start}";
        ExecStartPost = "${readiness}";
        ExecStop = "${stop}";
        Restart = "on-failure";
        RestartSec = "5s";
        TimeoutStartSec = "20min";
        TimeoutStopSec = "60s";
        Environment = [
          "HOME=${config.home.homeDirectory}"
          "XDG_CONFIG_HOME=${stateRoot}/podman-config"
        ];
      };
    };
  };
}
