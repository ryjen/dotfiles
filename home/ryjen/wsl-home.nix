{
  username,
  lib,
  ...
}:
{
  imports = [
    ./layers/lightweight.nix
    ./profiles/wsl.nix
  ]
  ++ lib.optional (builtins.pathExists ./user.local.nix) ./user.local.nix;

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
}
