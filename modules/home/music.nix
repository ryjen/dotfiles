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
      easyeffects
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
        "Shift+DELETE" = "run ${config.home.homeDirectory}/.local/bin/music-dislike";
      };
    };

    xdg.desktopEntries.music-window = {
      name = "Music Window";
      genericName = "Music Player";
      comment = "Open the local music library in mpv's graphical window";
      exec = "${musicWindow}";
      terminal = false;
      categories = [ "Audio" "Music" "Player" ];
    };

    home.sessionVariables.DUBNIUM_MUSIC_DIR = cfg.musicDirectory;

    home.file.".local/bin/music" = {
      source = ../../files/home/.local/bin/music;
      executable = true;
    };

    home.file.".local/bin/music-window" = {
      source = musicWindow;
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
  };
}
