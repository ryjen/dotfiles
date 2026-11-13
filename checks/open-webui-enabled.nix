{
  pkgs,
  home-manager,
}:
let
  inherit (pkgs) lib;
  evalOpenWebUI =
    enabled:
    (home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ../modules/home/open-webui.nix
        ({ lib, ... }: {
          options.dotfiles.host.userSystemd.enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
          config = {
            home = {
              username = "open-webui-check";
              homeDirectory = "/home/open-webui-check";
              stateVersion = "25.05";
            };
            dotfiles.openWebUI.enable = enabled;
          };
        })
      ];
    }).config;

  disabled = evalOpenWebUI false;
  enabled = evalOpenWebUI true;
  has = set: key: builtins.hasAttr key set;
  check = condition: message: if condition then "" else builtins.throw message;

  evaluated = builtins.concatStringsSep "" [
    (check (
      !(has disabled.systemd.user.services "dotfiles-open-webui")
      && !(has disabled.systemd.user.sockets "dotfiles-open-webui-ingress")
      && !(has disabled.systemd.user.sockets "dotfiles-open-webui-gateway")
    ) "disabled Open WebUI must create no user services or sockets")

    (check (
      has enabled.systemd.user.services "dotfiles-open-webui"
      && has enabled.systemd.user.services "dotfiles-open-webui-ingress"
      && has enabled.systemd.user.services "dotfiles-open-webui-gateway"
      && has enabled.systemd.user.sockets "dotfiles-open-webui-ingress"
      && has enabled.systemd.user.sockets "dotfiles-open-webui-gateway"
    ) "enabled Open WebUI must configure both socket proxies and the container service")

    (check (
      enabled.systemd.user.sockets.dotfiles-open-webui-ingress.Socket.ListenStream
      == "127.0.0.1:3000"
      && enabled.systemd.user.sockets.dotfiles-open-webui-gateway.Socket.ListenStream
      == "%t/dotfiles-open-webui/gateway/socket"
      && enabled.systemd.user.sockets.dotfiles-open-webui-gateway.Socket.SocketMode == "0600"
    ) "Open WebUI sockets must remain loopback-only and owner-private")

    (check (
      enabled.systemd.user.services.dotfiles-open-webui-ingress.Service.ProtectHome
      && enabled.systemd.user.services.dotfiles-open-webui-gateway.Service.ProtectHome
      && enabled.systemd.user.services.dotfiles-open-webui-ingress.Service.CapabilityBoundingSet == ""
      && enabled.systemd.user.services.dotfiles-open-webui-gateway.Service.CapabilityBoundingSet == ""
    ) "Open WebUI host socket proxies must retain service isolation")

    (check (
      enabled.systemd.user.services.dotfiles-open-webui.Service.Delegate
      && has enabled.systemd.user.services.dotfiles-open-webui.Service "ExecStartPost"
    ) "Rootless Open WebUI requires delegated cgroups and ingress readiness gating")
  ];
in
pkgs.runCommand "check-open-webui-enabled" { } ''
  ${evaluated}
  touch "$out"
''
