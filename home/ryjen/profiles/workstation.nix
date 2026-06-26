{ ... }:
{
  imports = [
    ./graphical.nix
  ];

  dotfiles.host.role = "workstation";
  dotfiles.host.graphical.enable = true;
  dotfiles.profiles.workstation.enable = true;
  dotfiles.agents.hermes.enable = true;
}
