{ ... }:
{
  imports = [
    ./graphical.nix
  ];

  dotfiles.host.role = "workstation";
  dotfiles.profiles.workstation.enable = true;
  dotfiles.agents.hermes.enable = true;
}
