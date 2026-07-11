{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.grimblast;
in
{
  options.dotfiles.grimblast.enable = lib.mkEnableOption "Grimblast screenshot helper";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.grimblast ];
  };
}
