{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.music;
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

    xdg.configFile."beets/config.yaml".text = ''
      directory: ${cfg.musicDirectory}
      library: ${config.xdg.configHome}/beets/library.db

      import:
        move: yes
        write: yes
        copy: no
        resume: yes
        incremental: yes

      paths:
        default: $albumartist/$album%aunique{}/$track $title
        singleton: Singles/$artist/$title
        comp: Compilations/$album%aunique{}/$track $title

      plugins:
        - fetchart
        - embedart
        - lastgenre
        - duplicates
        - missing
        - info
    '';

    xdg.configFile."ncmpcpp/config".text = ''
      mpd_host = "${cfg.mpd.listenAddress}"
      mpd_port = "${toString cfg.mpd.port}"
      music_directory = "${cfg.musicDirectory}"

      playlist_display_mode = "columns"
      browser_display_mode = "columns"
      search_engine_display_mode = "columns"

      autocenter_mode = "yes"
      display_volume_level = "yes"
      follow_now_playing_lyrics = "no"
    '';
  };
}
