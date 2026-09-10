{
  config,
  lib,
  pkgs,
  tidyfs,
  ...
}:
let
  cfg = config.dotfiles.tidyfs;
  tidyfsPackage = tidyfs.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.dotfiles.tidyfs.enable = lib.mkEnableOption "tidyfs filesystem cleanup CLI";

  config = lib.mkIf cfg.enable {
    home.packages = [ tidyfsPackage ];
  };
}
