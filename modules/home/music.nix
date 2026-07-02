{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.music;

  beetsConfig = pkgs.replaceVars ../../files/home/.config/beets/config.yaml {
    DUBNIUM_MUSIC_DIRECTORY = cfg.musicDirectory;
    DUBNIUM_BEETS_LIBRARY = "${config.xdg.configHome}/beets/library.db";
  };

  ncmpcppConfig = pkgs.replaceVars ../../files/home/.config/ncmpcpp/config {
    DUBNIUM_MPD_HOST = cfg.mpd.listenAddress;
    DUBNIUM_MPD_PORT = toString cfg.mpd.port;
    DUBNIUM_MUSIC_DIRECTORY = cfg.musicDirectory;
  };
in
{
  options.dotfiles.music = {
    enable = lib.mkEnableOption "low-profile local music library tooling";

    musicDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Music";
      description = "Directory managed by beets and indexed by MPD.";
    };

    mpd.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to run MPD as a Home Manager user service.";
    };

    mpd.listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address MPD listens on. Keep loopback unless explicitly exposing over a trusted network.";
    };

    mpd.port = lib.mkOption {
      type = lib.types.port;
      default = 6600;
      description = "MPD TCP port.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      beets
      jq
      mpc-cli
      ncmpcpp
    ];

    services.mpd = lib.mkIf cfg.mpd.enable {
      enable = true;
      musicDirectory = cfg.musicDirectory;

      network = {
        listenAddress = cfg.mpd.listenAddress;
        port = cfg.mpd.port;
      };

      extraConfig = ''
        auto_update "yes"
        restore_paused "yes"
        replaygain "album"

        audio_output {
          type "pipewire"
          name "PipeWire"
        }
      '';
    };

    xdg.configFile."beets/config.yaml".source = beetsConfig;
    xdg.configFile."ncmpcpp/config".source = ncmpcppConfig;
  };
}
