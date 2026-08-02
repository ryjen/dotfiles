{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.music;

  reaperPlugins = with pkgs; [
    dragonfly-reverb
    drumgizmo
    guitarix-vst
    lsp-plugins
    surge-xt
  ];

  reaperPluginBundle = pkgs.buildEnv {
    name = "reaper-plugin-bundle";
    paths = reaperPlugins;
    pathsToLink = [
      "/lib/clap"
      "/lib/lv2"
      "/lib/vst"
      "/lib/vst3"
    ];
  };

  swsPluginName = "reaper_sws-${pkgs.stdenv.hostPlatform.uname.processor}.so";

  pluginSearchPaths = format: [
    "${config.home.homeDirectory}/.${format}"
    "${config.home.homeDirectory}/.nix-profile/lib/${format}"
    "/etc/profiles/per-user/${config.home.username}/lib/${format}"
    "/run/current-system/sw/lib/${format}"
  ];

  musicWindow = pkgs.writeShellScript "music-window" ''
    set -euo pipefail

    music_dir="''${MPV_MUSIC_DIR:-''${DUBNIUM_MUSIC_DIR:-${cfg.musicDirectory}}}"

    mpv_music_window_args=(
      --force-window=yes
      --audio-display=embedded-first
      --loop-playlist=inf
      --save-position-on-quit
    )

    if [ "$#" -gt 0 ]; then
      exec ${pkgs.mpv}/bin/mpv "''${mpv_music_window_args[@]}" "$@"
    fi

    if [ ! -d "$music_dir" ]; then
      ${pkgs.libnotify}/bin/notify-send "Music Window" "Music directory not found: $music_dir" || true
      exit 1
    fi

    exec ${pkgs.mpv}/bin/mpv \
      "''${mpv_music_window_args[@]}" \
      --shuffle \
      "$music_dir"
  '';
in
{
  options.dotfiles.music = {
    enable = lib.mkEnableOption "local music playback and production tooling";

    musicDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Music";
      description = "Directory used by the music launcher.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      (with pkgs; [
        beets
        easyeffects
        hydrogen
        musescore
        playerctl
        python3
        reaper
        trash-cli
      ])
      ++ reaperPlugins;

    programs.mpv = {
      enable = true;

      scripts = with pkgs.mpvScripts; [
        mpris
      ];

      config = {
        audio-display = "no";
        save-position-on-quit = "yes";
      };

      bindings = {
        "Shift+DEL" = "run ${config.home.homeDirectory}/.local/bin/music-dislike";
      };
    };

    xdg.desktopEntries = {
      guitar-pro-reader = {
        name = "Guitar Pro Reader";
        genericName = "Guitar Tablature Reader";
        comment = "Open and play Guitar Pro tablature with MuseScore";
        exec = "${pkgs.musescore}/bin/mscore %F";
        icon = "mscore";
        terminal = false;
        categories = [
          "Audio"
          "AudioVideo"
          "Music"
        ];
        mimeType = [
          "application/x-guitar-pro"
          "application/x-guitar-pro5"
        ];
      };

      music-window = {
        name = "Music Window";
        genericName = "Music Player";
        comment = "Open the local music library in mpv's graphical window";
        exec = "${musicWindow}";
        terminal = false;
        categories = [
          "Audio"
          "Music"
          "Player"
        ];
      };
    };

    xdg.configFile."hypr/custom.d/40-guitar-pro.conf".text = ''
      # Open the Guitar Pro reader through its managed desktop entry.
      bind = SUPER, R, exec, ${pkgs.gtk3}/bin/gtk-launch guitar-pro-reader
    '';

    # Populate the standard per-user plugin directories that REAPER scans.
    # Recursive linking allows unrelated manually installed plugins to coexist.
    home.file = {
      ".clap" = {
        source = "${reaperPluginBundle}/lib/clap";
        recursive = true;
      };
      ".lv2" = {
        source = "${reaperPluginBundle}/lib/lv2";
        recursive = true;
      };
      ".vst" = {
        source = "${reaperPluginBundle}/lib/vst";
        recursive = true;
      };
      ".vst3" = {
        source = "${reaperPluginBundle}/lib/vst3";
        recursive = true;
      };

      ".local/share/dubnium/music-env".text = ''
        export DUBNIUM_MUSIC_DIR=${lib.escapeShellArg cfg.musicDirectory}
      '';

      ".local/bin/music" = {
        source = ../../files/home/.local/bin/music;
        executable = true;
      };

      ".local/bin/music-window" = {
        source = musicWindow;
        executable = true;
      };

      ".local/bin/music-toggle" = {
        source = ../../files/home/.local/bin/music-toggle;
        executable = true;
      };

      ".local/bin/music-eq" = {
        source = ../../files/home/.local/bin/music-eq;
        executable = true;
      };

      ".local/bin/music-dislike" = {
        source = ../../files/home/.local/bin/music-dislike;
        executable = true;
      };

      ".local/bin/music-retag-current" = {
        source = ../../files/home/.local/bin/music-retag-current;
        executable = true;
      };
    };

    # Also export the conventional search variables for other Linux audio hosts.
    home.sessionSearchVariables = {
      CLAP_PATH = pluginSearchPaths "clap";
      LV2_PATH = pluginSearchPaths "lv2";
      VST3_PATH = pluginSearchPaths "vst3";
      VST_PATH = pluginSearchPaths "vst";
    };

    home.sessionVariables.DUBNIUM_MUSIC_DIR = cfg.musicDirectory;

    # SWS is a REAPER extension rather than an audio plugin. Link its runtime
    # files into the REAPER resource directory while keeping the package immutable.
    xdg.configFile."REAPER/UserPlugins/${swsPluginName}".source =
      "${pkgs.reaper-sws-extension}/UserPlugins/${swsPluginName}";
    xdg.configFile."REAPER/Scripts/sws_python.py".source =
      "${pkgs.reaper-sws-extension}/Scripts/sws_python.py";
    xdg.configFile."REAPER/Scripts/sws_python64.py".source =
      "${pkgs.reaper-sws-extension}/Scripts/sws_python64.py";

    # DrumGizmo provides the plugin engine only; users select a separately
    # downloaded drum kit from within the plugin.
  };
}
