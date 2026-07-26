{
  username,
  lib,
  ...
}:
{
  imports = [
    ./layers/graphical.nix
    ./profiles/dubnium.nix
  ]
  ++ lib.optional (builtins.pathExists ./user.local.nix) ./user.local.nix;

  dotfiles.meeting.presentationOutput = "DP-1";
  dotfiles.meeting.cameraDevice = null;
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}
