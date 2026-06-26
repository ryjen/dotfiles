{ ... }:
{
  imports = [
    ./workstation.nix
  ];

  dotfiles.host.name = "nixos";
  dotfiles.profiles.android.enable = true;
  dotfiles.profiles.micrantha.enable = true;
  dotfiles.hypr.adoptedProfile = "dubnium";
}
