{ ... }:
{
  imports = [
    ./graphical.nix
  ];

  dotfiles.host.role = "laptop";
  dotfiles.host.laptop.enable = true;
  dotfiles.profiles.workstation.enable = true;
}
