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

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;
}
