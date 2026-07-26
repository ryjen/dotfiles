{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.music;

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
    enable = lib.mkEnableOption "low-profile local music playback tooling";

    musicDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Music";
      description = "Directory used by the music launcher.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      beets
      easyeffects
      musescore
      playerctl
      python3
      trash-cli
    ];

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
      # Open the Guitar Pro reader through its desktop entry.
      bind = SUPER, R, exec, ${pkgs.glib}/bin/gapplication launch org.musescore.MuseScore
    '';

    home.sessionVariables.DUBNIUM_MUSIC_DIR = cfg.musicDirectory;

    home.file.".local/share/dubnium/music-env".text = ''
      export DUBNIUM_MUSIC_DIR=${lib.escapeShellArg cfg.musicDirectory}
    '';

    home.file.".local/bin/music" = {
      source = ../../files/home/.local/bin/music;
      executable = true;
    };

    home.file.".local/bin/music-window" = {
      source = musicWindow;
      executable = true;
    };

    home.file.".local/bin/music-toggle" = {
      source = ../../files/home/.local/bin/music-toggle;
      executable = true;
    };

    home.file.".local/bin/music-eq" = {
      source = ../../files/home/.local/bin/music-eq;
      executable = true;
    };

    home.file.".local/bin/music-dislike" = {
      source = ../../files/home/.local/bin/music-dislike;
      executable = true;
    };

    home.file.".local/bin/music-retag-current" = {
      source = ../../files/home/.local/bin/music-retag-current;
      executable = true;
    };
  };
}
