{
  username,
  lib,
  ...
}:
{
  imports = [
    ./layers/lightweight.nix
    ./profiles/headless.nix
  ]
  ++ lib.optional (builtins.pathExists ./user.nix) ./user.nix;

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
}
