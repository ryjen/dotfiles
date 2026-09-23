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
    meeting = {
      enable = lib.mkDefault true;
      zoom.enable = lib.mkDefault true;
      teams.enable = lib.mkDefault true;
      phoneCamera.enable = lib.mkDefault true;
    };
  };
}
