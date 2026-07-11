{ lib, ... }:
{
  imports = [
    ./workstation.nix
  ];

  dotfiles.host.name = "dubnium";
  dotfiles.profiles.browser.enable = lib.mkDefault true;
  dotfiles.profiles.android.enable = lib.mkDefault false;
  dotfiles.profiles.micrantha.enable = lib.mkDefault false;
  dotfiles.profiles.office.enable = lib.mkDefault true;
  dotfiles.opsCadence.enable = lib.mkDefault true;
  dotfiles.hypr.adoptedProfile = "dubnium";

  dotfiles.music = {
    enable = lib.mkDefault true;
    musicDirectory = lib.mkDefault "/mnt/isotope/Music";
  };
}
