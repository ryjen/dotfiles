{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.tidyfs;
in
{
  options.dotfiles.tidyfs.enable = lib.mkEnableOption "tidyfs filesystem cleanup CLI";

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.callPackage ../../packages/tidyfs.nix { })
    ];
  };
}
