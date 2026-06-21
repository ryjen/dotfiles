{ lib, ... }:
{
  dotfiles.agents.hermes.enable = true;
  dotfiles.profiles.workstation.enable = true;
  dotfiles.profiles.android.enable = true;
  dotfiles.profiles.micrantha.enable = true;
  dotfiles.hypr.adoptedProfile = "technetium";

  xdg.configFile."waybar/config.jsonc".source = lib.mkForce ../../../files/home/.config/waybar/config-technetium.jsonc;
}
