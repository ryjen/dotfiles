{
  username,
  lib,
  ...
}:
{
  imports = [
    ./layers/graphical.nix
    ./profiles/verify.nix
  ]
  ++ lib.optional (builtins.pathExists ./user.local.nix) ./user.local.nix;

  dotfiles.unreal = {
    enable = true;
    engineRoot = "/tmp/unreal-engine";
    cacheRoot = "/tmp/unreal-cache";
  };

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}
