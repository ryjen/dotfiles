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
      exec = "${config.home.homeDirectory}/.local/bin/music-window";
      terminal = false;
      categories = [ "Audio" "Music" "Player" ];
    };

    home.sessionVariables.DUBNIUM_MUSIC_DIR = cfg.musicDirectory;

    home.file.".local/bin/music" = {
      source = ../../files/home/.local/bin/music;
      executable = true;
    };

    home.file.".local/bin/music-window" = {
      source = ../../files/home/.local/bin/music-window;
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

    home.file.".local/bin/music-status" = {
      source = ../../files/home/.local/bin/music-status;
      executable = true;
    };
  };
}
