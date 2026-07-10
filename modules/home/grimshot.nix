{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.grimshot;
in
{
  options.dotfiles.grimshot.enable = lib.mkEnableOption "Grimshot screenshot helper";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.sway-contrib.grimshot ];
  };
}
