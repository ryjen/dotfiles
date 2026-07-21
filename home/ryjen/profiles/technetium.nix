{ lib, ... }:
{
  imports = [
    ./laptop.nix
  ];

  dotfiles.host.name = "technetium";
  dotfiles.profiles.browser.enable = lib.mkDefault true;
  dotfiles.profiles.android.enable = lib.mkDefault false;
  dotfiles.profiles.micrantha.enable = lib.mkDefault false;
  dotfiles.hypr.adoptedProfile = "technetium";
  dotfiles.waybar.variant = "laptop";
}
