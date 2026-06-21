{
  username,
  lib,
  ...
}:
{
  imports =
    [
      ./layers/lightweight.nix
      ./profiles/verify.nix
    ]
    ++ lib.optional (builtins.pathExists ./git-local.nix) ./git-local.nix;

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
}
