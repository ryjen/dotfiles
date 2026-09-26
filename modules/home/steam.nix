{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.steam;
in
{
  options.dotfiles.steam.enable = lib.mkEnableOption "Steam game client";

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.steam
    ];
  };
}
