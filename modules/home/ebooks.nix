{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.ebooks;
in
{
  options.dotfiles.ebooks.enable = lib.mkEnableOption "ebook library management and reading tooling";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      calibre
    ];
  };
}
