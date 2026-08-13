{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.music.mpd;
  musicCfg = config.dotfiles.music;
  playlistDirectory = "${config.xdg.dataHome}/mpd/playlists";
in
{
  options.dotfiles.music.mpd.enable = lib.mkEnableOption "MPD-backed managed music-library playback";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = musicCfg.enable;
        message = "dotfiles.music.mpd.enable requires dotfiles.music.enable";
      }
    ];

    services.mpd = {
      enable = true;
      musicDirectory = musicCfg.musicDirectory;
      playlistDirectory = playlistDirectory;
      network = {
        listenAddress = "127.0.0.1";
        port = 6600;
      };
      extraConfig = ''
        # The tagged filesystem remains a projection of the beets library.
        # Watch it directly so MPD stays current even before the optional
        # beets mpdupdate plugin is enabled in the user-owned beets config.
        auto_update "yes"

        # Keep the MPD control plane local by default. Remote access should be
        # an explicit capability rather than an accidental LAN service.
        zeroconf_enabled "no"

        replaygain "auto"

        audio_output {
          type "pipewire"
          name "PipeWire"
        }
      '';
    };

    services.mpd-mpris = {
      enable = true;
      mpd.useLocal = true;
    };

    programs.rmpc = {
      enable = true;
      config = ''
        (
            address: "127.0.0.1:6600",
            password: None,
            theme: None,
            cache_dir: None,
            on_song_change: None,
            volume_step: 5,
            max_fps: 30,
            scrolloff: 4,
            wrap_navigation: false,
            enable_mouse: true,
            enable_config_hot_reload: true,
            status_update_interval_ms: 1000,
            select_current_song_on_change: true,
            browser_song_sort: [Disc, Track, Artist, Title],
        )
      '';
    };

    # Keep the main beets config user-owned. This drop-in can be included from
    # ~/.config/beets/config.yaml without Home Manager replacing that file.
    xdg.configFile."beets/dotfiles-mpd.yaml".text = ''
      mpd:
        host: 127.0.0.1
        port: 6600
      playlist:
        auto: true
        playlist_dir: ${builtins.toJSON playlistDirectory}
        relative_to: ${builtins.toJSON musicCfg.musicDirectory}
      smartplaylist:
        playlist_dir: ${builtins.toJSON playlistDirectory}
        relative_to: ${builtins.toJSON musicCfg.musicDirectory}
        playlists:
          - name: recently-added.m3u
            query: "added:-4w.."
    '';

    xdg.desktopEntries.music-library = {
      name = "Music Library";
      genericName = "Music Library";
      comment = "Browse and control the managed music library with rmpc";
      exec = "${pkgs.alacritty}/bin/alacritty --title \"Music Library\" -e ${pkgs.rmpc}/bin/rmpc";
      terminal = false;
      categories = [
        "Audio"
        "AudioVideo"
        "Music"
        "Player"
      ];
    };

    home.file.".local/bin/music-playerctl" = {
      source = ../../files/home/.local/bin/music-playerctl;
      executable = true;
    };
  };
}
