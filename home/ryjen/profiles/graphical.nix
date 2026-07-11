{ lib, ... }:
{
  dotfiles.host.graphical.enable = true;
  dotfiles.graphical.keyring.enable = lib.mkDefault true;
}
