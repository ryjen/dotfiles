{ lib, ... }:
{
  imports = [
    ./laptop.nix
  ];

  dotfiles.host.name = "technetium";
  dotfiles.profiles.browser.enable = true;
  dotfiles.profiles.android.enable = false;
  dotfiles.profiles.micrantha.enable = false;
  dotfiles.hypr.adoptedProfile = "technetium";

  xdg.configFile."waybar/config.jsonc".source =
    lib.mkForce ../../../files/home/.config/waybar/config-technetium.jsonc;
}
