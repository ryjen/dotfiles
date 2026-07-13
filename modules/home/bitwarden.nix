{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.bitwarden;
in
{
  options.dotfiles.bitwarden = {
    cli.enable = lib.mkEnableOption "Bitwarden command-line client";
    desktop.enable = lib.mkEnableOption "Bitwarden desktop client";
  };

  config = {
    home.packages =
      lib.optionals cfg.cli.enable [ pkgs.bitwarden-cli ]
      ++ lib.optionals cfg.desktop.enable [ pkgs.bitwarden-desktop ];
  };
}
