{
  lib,
  dockerTools,
  runCommand,
  writeShellScript,
  bash,
  coreutils,
  cacert,
  socat,
  open-webui,
}:
let
  imageRoot = runCommand "dotfiles-open-webui-image-root" { } ''
    mkdir -p "$out"/etc "$out"/tmp "$out"/run/open-webui/ingress "$out"/run/open-webui/gateway "$out"/var/lib/open-webui/data
    printf 'root:x:0:0:root:/var/lib/open-webui:/bin/sh\n' > "$out"/etc/passwd
    printf 'root:x:0:\n' > "$out"/etc/group
    chmod 1777 "$out"/tmp
  '';

  entrypoint = writeShellScript "dotfiles-open-webui-entrypoint" ''
    set -euo pipefail
    cd /var/lib/open-webui
    export DATA_DIR=/var/lib/open-webui/data
    # open-webui serve reads .webui_secret_key from the current directory.

    # Created on the host before container startup, never stored in the image.
    if [[ ! -f .webui_secret_key || -L .webui_secret_key || ! -s .webui_secret_key ]]; then
      echo "Missing or invalid Open WebUI signing key" >&2
      exit 1
    fi

    ${socat}/bin/socat UNIX-LISTEN:/run/open-webui/ingress/socket,unlink-early,mode=0600,fork TCP:127.0.0.1:8081 &
    ingress_pid=$!

    ${socat}/bin/socat TCP-LISTEN:8080,bind=127.0.0.1,reuseaddr,fork UNIX-CONNECT:/run/open-webui/gateway/socket &
    gateway_pid=$!

    ${open-webui}/bin/open-webui serve --host 127.0.0.1 --port 8081 &
    webui_pid=$!
    trap 'kill "$ingress_pid" "$gateway_pid" "$webui_pid" 2>/dev/null || true' EXIT
    wait -n "$ingress_pid" "$gateway_pid" "$webui_pid"
  '';
in
dockerTools.buildLayeredImage {
  name = "dotfiles/open-webui";
  tag = open-webui.version;
  contents = [
    imageRoot
    entrypoint
    bash
    coreutils
    cacert
    socat
    open-webui
  ];
  config = {
    User = "0:0";
    WorkingDir = "/var/lib/open-webui";
    Entrypoint = [ "${entrypoint}" ];
    Env = [
      "HOME=/var/lib/open-webui"
      "PATH=${lib.makeBinPath [ bash coreutils socat open-webui ]}"
      "SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
    Labels = {
      "org.opencontainers.image.title" = "Dotfiles Open WebUI";
      "org.opencontainers.image.description" = "Local UI with networkless rootless Podman and a Supervisor-only socket";
      "org.opencontainers.image.version" = open-webui.version;
    };
  };
