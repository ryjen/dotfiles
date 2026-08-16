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

  # Keep Hermes execution/state on Dubnium. Hermes Desktop connects to the
  # remote `hermes serve`/dashboard endpoint; the messaging gateway remains a
  # separate Dubnium service (`svc:hermes-gateway`).
  home.sessionVariables.HERMES_DESKTOP_REMOTE_URL =
    "https://hermes.tail4d84c.ts.net";
}
