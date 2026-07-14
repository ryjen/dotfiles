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

  dotfiles.bitwarden.cli.enable = lib.mkDefault true;
  dotfiles.bitwarden.desktop.enable = lib.mkDefault true;

  # Canonical music directory for shells and graphical-session processes.
  dotfiles.music = {
    enable = lib.mkDefault true;
    musicDirectory = lib.mkDefault "/mnt/isotope/Music";
  };
}
