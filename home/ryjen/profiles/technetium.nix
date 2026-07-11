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

  xdg.configFile."waybar/config.jsonc".source =
    lib.mkForce ../../../files/home/.config/waybar/config-technetium.jsonc;
}
