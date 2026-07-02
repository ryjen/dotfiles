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
      mpv
      playerctl
    ];

    home.sessionVariables.DUBNIUM_MUSIC_DIR = cfg.musicDirectory;

    home.file.".local/bin/music" = {
      source = ../../files/home/.local/bin/music;
      executable = true;
    };
  };
}
