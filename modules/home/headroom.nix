{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.headroom;
in
{
  options.dotfiles.headroom = {
    proxy = {
      enable = lib.mkEnableOption "Headroom proxy user service";

      port = lib.mkOption {
        type = lib.types.port;
        default = 8787;
        description = "Port for the Headroom proxy.";
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Host address for the Headroom proxy.";
      };

      package = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/.local/bin/headroom";
        description = "Path to the headroom CLI binary (uv tool-installed).";
      };
    };
  };

  config = lib.mkIf cfg.proxy.enable {
    systemd.user.services.headroom-proxy = {
      Unit = {
        Description = "Headroom context compression proxy";
        Documentation = "https://headroom-docs.vercel.app";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${cfg.proxy.package} proxy --host ${cfg.proxy.host} --port ${toString cfg.proxy.port}";
        Restart = "always";
        RestartSec = "5s";
        Environment = [
          "PATH=%h/.local/bin:%h/.local/share/pip/bin:%h/.venv/bin"
          "LD_LIBRARY_PATH=${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}"
        ];
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
