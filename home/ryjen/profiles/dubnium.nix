{ ... }:
{
  imports = [
    ./workstation.nix
  ];

  dotfiles.host.name = "dubnium";
  dotfiles.profiles.browser.enable = true;
  dotfiles.profiles.android.enable = false;
  dotfiles.profiles.micrantha.enable = false;
  dotfiles.hypr.adoptedProfile = "dubnium";

  dotfiles.music = {
    enable = true;
    musicDirectory = "/mnt/isotope/music";
  };
}
