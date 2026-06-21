{ ... }:
{
  imports = [
    ./workstation.nix
  ];

  dotfiles.host.name = "nixos";
  dotfiles.agents.hermes.enable = true;
  dotfiles.profiles.android.enable = true;
  dotfiles.profiles.micrantha.enable = true;
  dotfiles.hypr.adoptedProfile = "dubnium";
}
