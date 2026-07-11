{
  username,
  ...
}:
{
  imports = [
    ./layers/lightweight.nix
    ./profiles/wsl.nix
    ./user.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
}
