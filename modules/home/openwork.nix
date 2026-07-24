{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.openwork;
  openworkPackage = pkgs.callPackage ../../packages/openwork.nix { };

  workspaceDeclarations = lib.concatMapStringsSep "\n" (
    path: "workspace_paths+=(${lib.escapeShellArg path})"
  ) cfg.sandbox.workspacePaths;

  sandboxedOpenwork = pkgs.writeShellApplication {
    name = "openwork";
    runtimeInputs = [
      pkgs.bubblewrap
      pkgs.coreutils
      pkgs.xdg-dbus-proxy
    ];
    text = ''
      set -euo pipefail

      : "''${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR must be set}"
      : "''${WAYLAND_DISPLAY:?WAYLAND_DISPLAY must be set}"
      : "''${DBUS_SESSION_BUS_ADDRESS:?DBUS_SESSION_BUS_ADDRESS must be set}"

      readonly sandbox_root="''${XDG_DATA_HOME:-$HOME/.local/share}/openwork-sandbox"
      readonly sandbox_home="$sandbox_root/home"
      readonly proxy_dir="$(mktemp -d "$XDG_RUNTIME_DIR/openwork-sandbox.XXXXXX")"
      readonly proxy_socket="$proxy_dir/session-bus"

      mkdir -p \
        "$sandbox_home/.cache" \
        "$sandbox_home/.config" \
        "$sandbox_home/.local/share"
      chmod 0700 "$sandbox_root" "$sandbox_home" "$proxy_dir"

      xdg-dbus-proxy \
        "$DBUS_SESSION_BUS_ADDRESS" \
        "$proxy_socket" \
        --filter \
        --talk=org.freedesktop.portal.Desktop \
        --talk=org.freedesktop.Notifications &
      proxy_pid=$!
      app_pid=""

      cleanup() {
        if [[ -n "$app_pid" ]]; then
          kill "$app_pid" 2>/dev/null || true
          wait "$app_pid" 2>/dev/null || true
        fi
        kill "$proxy_pid" 2>/dev/null || true
        wait "$proxy_pid" 2>/dev/null || true
        rm -rf "$proxy_dir"
      }
      trap cleanup EXIT
      trap 'exit 130' INT
      trap 'exit 143' TERM

      for _ in $(seq 1 50); do
        [[ -S "$proxy_socket" ]] && break
        kill -0 "$proxy_pid" 2>/dev/null || {
          echo "OpenWork D-Bus proxy exited before becoming ready" >&2
          exit 1
        }
        sleep 0.02
      done
      [[ -S "$proxy_socket" ]] || {
        echo "OpenWork D-Bus proxy did not become ready" >&2
        exit 1
      }

      args=(
        --die-with-parent
        --new-session
        --unshare-all
        ${lib.optionalString cfg.sandbox.allowNetwork "--share-net"}
        --ro-bind / /
        --tmpfs /home
        --tmpfs /root
        --tmpfs /tmp
        --tmpfs "$XDG_RUNTIME_DIR"
        --proc /proc
        --dev /dev
        --dir "$HOME"
        --bind "$sandbox_home" "$HOME"
        --dir "$proxy_dir"
        --bind "$proxy_socket" "$proxy_socket"
        --clearenv
        --setenv HOME "$HOME"
        --setenv USER "''${USER:-ryjen}"
        --setenv LOGNAME "''${LOGNAME:-''${USER:-ryjen}}"
        --setenv PATH "$PATH"
        --setenv SHELL "''${SHELL:-/bin/sh}"
        --setenv LANG "''${LANG:-C.UTF-8}"
        --setenv XDG_CACHE_HOME "$HOME/.cache"
        --setenv XDG_CONFIG_HOME "$HOME/.config"
        --setenv XDG_DATA_HOME "$HOME/.local/share"
        --setenv XDG_RUNTIME_DIR "$XDG_RUNTIME_DIR"
        --setenv XDG_SESSION_TYPE "''${XDG_SESSION_TYPE:-wayland}"
        --setenv WAYLAND_DISPLAY "$WAYLAND_DISPLAY"
        --setenv DBUS_SESSION_BUS_ADDRESS "unix:path=$proxy_socket"
      )

      for variable in XDG_CURRENT_DESKTOP DESKTOP_SESSION ELECTRON_OZONE_PLATFORM_HINT; do
        if [[ -n "''${!variable:-}" ]]; then
          args+=(--setenv "$variable" "''${!variable}")
        fi
      done

      for hidden_path in /mnt /media /srv /run/secrets /run/credentials; do
        if [[ -d "$hidden_path" ]]; then
          args+=(--tmpfs "$hidden_path")
        fi
      done

      if [[ -e "/dev/dri" ]]; then
        args+=(--dir /dev/dri)
        args+=(--dev-bind /dev/dri /dev/dri)
      fi

      wayland_socket="$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
      [[ -S "$wayland_socket" ]] || {
        echo "Wayland socket not found: $wayland_socket" >&2
        exit 1
      }
      args+=(--bind "$wayland_socket" "$wayland_socket")

      if [[ -S "$XDG_RUNTIME_DIR/pipewire-0" ]]; then
        args+=(--bind "$XDG_RUNTIME_DIR/pipewire-0" "$XDG_RUNTIME_DIR/pipewire-0")
      fi

      if [[ -S "$XDG_RUNTIME_DIR/pulse/native" ]]; then
        args+=(--dir "$XDG_RUNTIME_DIR/pulse")
        args+=(--bind "$XDG_RUNTIME_DIR/pulse/native" "$XDG_RUNTIME_DIR/pulse/native")
      fi

      ${lib.optionalString cfg.sandbox.allowSshAgent ''
        if [[ -n "''${SSH_AUTH_SOCK:-}" && -S "$SSH_AUTH_SOCK" ]]; then
          ssh_socket_dir="$(dirname "$SSH_AUTH_SOCK")"
          args+=(--dir "$ssh_socket_dir")
          args+=(--bind "$SSH_AUTH_SOCK" "$SSH_AUTH_SOCK")
          args+=(--setenv SSH_AUTH_SOCK "$SSH_AUTH_SOCK")
        fi
      ''}

      workspace_paths=()
      ${workspaceDeclarations}

      for workspace in "''${workspace_paths[@]}"; do
        resolved="$(realpath -e "$workspace")"
        case "$resolved" in
          "$HOME"/*) ;;
          *)
            echo "OpenWork workspace must be beneath $HOME: $workspace" >&2
            exit 1
            ;;
        esac

        relative="$(realpath --relative-to="$HOME" "$resolved")"
        mkdir -p "$sandbox_home/$relative"
        args+=(--bind "$resolved" "$resolved")
      done

      bwrap "''${args[@]}" ${openworkPackage}/bin/openwork "$@" &
      app_pid=$!

      set +e
      wait "$app_pid"
      status=$?
      set -e
      app_pid=""
      exit "$status"
    '';
  };

  openwork = if cfg.sandbox.enable then sandboxedOpenwork else openworkPackage;
in
{
  options.dotfiles.openwork = {
    enable = lib.mkEnableOption "OpenWork desktop application";

    sandbox = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Run OpenWork in a Bubblewrap sandbox";
      };

      workspacePaths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "${config.home.homeDirectory}/Projects" ];
        description = "Home-directory paths exposed read-write inside the OpenWork sandbox";
      };

      allowNetwork = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Allow network access from the OpenWork sandbox";
      };

      allowSshAgent = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Expose SSH_AUTH_SOCK to the OpenWork sandbox";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ openwork ];

    xdg.desktopEntries.openwork = {
      name = "OpenWork";
      genericName = "AI workflow desktop";
      comment = "Run and share AI workflows";
      exec = "openwork %U";
      icon = "applications-development";
      terminal = false;
      startupNotify = true;
      categories = [
        "Development"
        "Utility"
      ];
      mimeType = [ "x-scheme-handler/openwork" ];
      settings.StartupWMClass = "OpenWork";
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications."x-scheme-handler/openwork" = "openwork.desktop";
    };
  };
}
