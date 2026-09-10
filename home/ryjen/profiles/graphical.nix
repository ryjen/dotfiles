{ lib, ... }:
{
  dotfiles = {
    host.graphical.enable = true;
    graphical.keyring.enable = lib.mkDefault true;
    idle.enable = lib.mkDefault true;
  };
}
