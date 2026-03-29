{
  username,
  ...
}:
{
  imports = [
    ../../modules/home/default.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
}
