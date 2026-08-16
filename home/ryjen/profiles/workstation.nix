{ lib, ... }:
{
  imports = [
    ./graphical.nix
  ];

  dotfiles.host.role = "workstation";
  dotfiles.profiles.workstation.enable = true;
  dotfiles.opencode.enable = lib.mkDefault true;
  dotfiles.meeting.enable = lib.mkDefault true;
  dotfiles.agents.hermes.enable = lib.mkDefault true;
  dotfiles.agents.antigravity.enable = lib.mkDefault true;
  dotfiles.headroom.proxy.enable = lib.mkDefault true;
  dotfiles.playwright.enable = lib.mkDefault true;
}
