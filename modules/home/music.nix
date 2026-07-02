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
      description = "Directory used by the mpv music launcher.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      mpv
      playerctl
    ];

    home.file.".local/bin/mpv-music" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        music_dir="''${MPV_MUSIC_DIR:-${cfg.musicDirectory}}"

        if [ ! -d "$music_dir" ]; then
          printf 'music directory not found: %s\n' "$music_dir" >&2
          exit 1
        fi

        exec ${pkgs.mpv}/bin/mpv \
          --shuffle \
          --loop-playlist=inf \
          --save-position-on-quit \
          "$music_dir"
      '';
    };
  };
}
