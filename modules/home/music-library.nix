{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.music.mpd;
  musicCfg = config.dotfiles.music;
  machineProfile = config.dotfiles.host.name;
  machineProfileName = if machineProfile == null then "unconfigured" else machineProfile;
  playlistDirectory = "${config.xdg.dataHome}/mpd/playlists";
  rmpcConfig = builtins.readFile ../../files/home/.config/rmpc/base.ron;
  mpdCustomProfilesRoot = ../../files/home/.config/mpd/custom.d;
  mpdCustomProfile = mpdCustomProfilesRoot + "/${machineProfileName}";
  hasMpdCustomProfile = machineProfile != null && builtins.pathExists mpdCustomProfile;
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

    home.packages = [ pkgs.mpc ];

    services.mpd = {
      enable = true;
      inherit (musicCfg) musicDirectory;
      inherit playlistDirectory;
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

        # MPD supports native optional includes. Home Manager owns the root
        # config and materializes promoted, profile-scoped configctl fragments.
        # Unpromoted custom fragments override the promoted profile layer, and
        # local.conf remains machine-local with highest precedence.
        include_optional "${config.xdg.configHome}/mpd/custom.d/${machineProfileName}/*.conf"
        include_optional "${config.xdg.configHome}/mpd/custom.d/*.conf"
        include_optional "${config.xdg.configHome}/mpd/local.conf"
      '';
    };

    services.mpd-mpris = {
      enable = true;
      mpd.useLocal = true;
    };

    # Tags, albums and the tagged filesystem change as beets is used and the
    # library is refreshed; regenerate the smart playlists on a daily cadence.
    systemd.user.services.beets-smartplaylists = {
      Unit = {
        Description = "Regenerate beets smart playlists for MPD";
        After = [
          "mpd.service"
          "beets-smartplaylists.timer"
        ];
        Wants = [ "beets-smartplaylists.timer" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.beets}/bin/beet splupdate";
      };
    };

    systemd.user.timers.beets-smartplaylists = {
      Unit = {
        Description = "Daily regeneration of beets smart playlists";
      };
      Timer = {
        OnCalendar = "daily";
        Persistent = true;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };

    programs.rmpc = {
      enable = true;
      config = rmpcConfig;
    };

    xdg.configFile = {
      # Keep the main beets config user-owned. This drop-in can be included
      # from ~/.config/beets/config.yaml without replacing that file.
      "beets/dotfiles-mpd.yaml".text = ''
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
            - name: Genre - Rock.m3u
              query: "genres:Rock"
            - name: Genre - Metal.m3u
              query: "genres:Metal"
            - name: Genre - Alternative & Punk.m3u
              query: "genres::Alternative|Punk"
            - name: Genre - Pop.m3u
              query: "genres:Pop"
            - name: Genre - Electronic & Dance.m3u
              query: "genres::Electronic|Dance|House|Techno|Trance|Dubstep|Disco|Electro|Ambient|EDM"
            - name: Genre - Hip-Hop & Rap.m3u
              query: "genres::Hip|Rap"
            - name: Genre - R&B, Soul & Funk.m3u
              query: "genres::R&B|RnB|Soul|Funk|rhythm"
            - name: Genre - Jazz.m3u
              query: "genres:Jazz"
            - name: Genre - Country.m3u
              query: "genres:Country"
            - name: Genre - Blues.m3u
              query: "genres:Blues"
            - name: Genre - Classical.m3u
              query: "genres:Classical"
            - name: Genre - Reggae.m3u
              query: "genres:Reggae"
            - name: Genre - Folk.m3u
              query: "genres:Folk"
            - name: Decade - 1950s.m3u
              query: "year:1950..1959"
            - name: Decade - 1960s.m3u
              query: "year:1960..1969"
            - name: Decade - 1970s.m3u
              query: "year:1970..1979"
            - name: Decade - 1980s.m3u
              query: "year:1980..1989"
            - name: Decade - 1990s.m3u
              query: "year:1990..1999"
            - name: Decade - 2000s.m3u
              query: "year:2000..2009"
            - name: Decade - 2010s.m3u
              query: "year:2010..2019"
            - name: Decade - 2020s.m3u
              query: "year:2020..2029"
            - name: Recently Added Albums.m3u
              album_query: "added:-30d.."
            - name: Longer Tracks.m3u
              query: "length:600.."
      '';
    }
    // lib.optionalAttrs hasMpdCustomProfile {
      # configctl promote stores reviewed fragments under
      # files/home/.config/mpd/custom.d/<profile>/. Project that profile back
      # into the runtime tree without taking ownership of root custom.d/*.conf.
      "mpd/custom.d/${machineProfileName}" = {
        source = mpdCustomProfile;
        recursive = true;
      };
    };

    # Music Library is the sole managed-music launcher. rmpc owns interactive
    # library browsing, queue management and persisted playlists.
    xdg.desktopEntries.music-library = {
      name = "Music Library";
      genericName = "Music Library";
      comment = "Browse the MPD library, queue and playlists with rmpc";
      exec = "${config.home.homeDirectory}/.local/bin/dub-terminal --title \"Music Library\" ${pkgs.rmpc}/bin/rmpc";
      terminal = false;
      categories = [
        "Audio"
        "AudioVideo"
        "Music"
        "Player"
      ];
    };

    # Waybar integration is an implementation detail of the managed MPD layer,
    # not a user-facing music CLI. Keep these helpers out of PATH.
    home.file = {
      ".local/libexec/dubnium-music-control" = {
        source = ../../files/home/.local/libexec/dubnium-music-control;
        executable = true;
      };
      ".local/libexec/dubnium-music-status" = {
        source = ../../files/home/.local/libexec/dubnium-music-status;
        executable = true;
      };
    };
  };
}
