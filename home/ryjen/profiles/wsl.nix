{ ... }:
{
  imports = [
    ./headless.nix
  ];

  dotfiles.host = {
    name = "wsl";
    wsl.enable = true;
    userSystemd.enable = false;
  };
}
