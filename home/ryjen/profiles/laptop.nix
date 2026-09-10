{ lib, ... }:
{
  imports = [
    ./graphical.nix
  ];

  dotfiles = {
    host = {
      role = "laptop";
      laptop.enable = true;
    };
    profiles.workstation.enable = true;
    meeting.enable = lib.mkDefault true;
  };
}
