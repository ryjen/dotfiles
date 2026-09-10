{ lib, ... }:
{
  imports = [
    ./graphical.nix
  ];

  dotfiles = {
    host.role = "workstation";
    profiles.workstation.enable = true;
    ebooks.enable = lib.mkDefault true;
    opencode.enable = lib.mkDefault true;
    meeting.enable = lib.mkDefault true;
    agents = {
      hermes.enable = lib.mkDefault true;
      antigravity.enable = lib.mkDefault true;
    };
    headroom.proxy.enable = lib.mkDefault true;
    playwright.enable = lib.mkDefault true;
  };
}
