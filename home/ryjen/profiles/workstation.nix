{ lib, ... }:
{
  imports = [
    ./graphical.nix
  ];

  dotfiles.host.role = "workstation";
  dotfiles.profiles.workstation.enable = true;
  dotfiles.meeting.enable = lib.mkDefault true;
  dotfiles.agents.hermes.enable = lib.mkDefault true;
  dotfiles.agents.antigravity.enable = lib.mkDefault true;
  dotfiles.headroom.proxy.enable = lib.mkDefault true;
}
