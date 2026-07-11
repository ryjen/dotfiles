{
  username,
  ...
}:
{
  imports = [
    ./layers/lightweight.nix
    ./profiles/headless.nix
    ./user.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;
}
