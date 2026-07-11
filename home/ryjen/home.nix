{
  username,
  lib,
  ...
}:
{
  imports = [
    ./layers/graphical.nix
    ./profiles/nixos.nix
  ]
  ++ lib.optional (builtins.pathExists ./user.nix) ./user.nix;

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
}
