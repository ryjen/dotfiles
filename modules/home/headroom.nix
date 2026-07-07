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
        default = "${config.home.homeDirectory}/.local/libexec/headroom-proxy";
        description = "Path to the Headroom proxy launcher. The launcher prefers uv tool-installed Headroom and falls back to the legacy pip global during migration.";
      };
    };
  };

  config = lib.mkIf cfg.proxy.enable {
    home.file.".local/bin/rtk" = {
      source = ../../files/home/.local/bin/rtk;
      executable = true;
    };

    home.file.".local/libexec/headroom-proxy" = {
      source = ../../files/home/.local/libexec/headroom-proxy;
      executable = true;
    };

    systemd.user.services.headroom-proxy = {
      Unit = {
        Description = "Headroom context compression proxy";
        Documentation = "https://headroom-docs.vercel.app";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${cfg.proxy.package} --host ${cfg.proxy.host} --port ${toString cfg.proxy.port}";
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
