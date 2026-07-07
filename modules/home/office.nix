{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.profiles.office;
in
{
  options.dotfiles.profiles.office.enable = lib.mkEnableOption "office productivity suite";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      onlyoffice-desktopeditors
    ];
  };
}
