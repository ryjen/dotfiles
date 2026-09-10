{ lib, ... }:
{
  imports = [
    ./workstation.nix
  ];

  dotfiles = {
    host.name = "nixos";
    profiles = {
      android.enable = true;
      micrantha.enable = true;
    };
    hypr.adoptedProfile = "dubnium";
    opencode.configProfile = lib.mkDefault "dubnium";
  };
}
