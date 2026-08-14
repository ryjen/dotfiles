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
  dotfiles.openwork.enable = lib.mkDefault true;
  dotfiles.openwork.sandbox.allowSshAgent = lib.mkDefault true;
  dotfiles.hypr.adoptedProfile = "dubnium";

  # When Unreal is explicitly enabled, use the native Linux filesystem mounted
  # from the optional isotope-backed storage image. This path selection alone
  # does not enable Unreal or the storage module.
  dotfiles.unreal.engineRoot = lib.mkDefault "/srv/unreal/Engine/5.8";

  dotfiles.bitwarden.cli.enable = lib.mkDefault true;
  dotfiles.bitwarden.desktop.enable = lib.mkDefault false;

  # Canonical music directory for shells and graphical-session processes.
  dotfiles.music = {
    enable = lib.mkDefault true;
    musicDirectory = lib.mkDefault "/mnt/isotope/Music";
    mpd.enable = lib.mkDefault true;
  };
}
