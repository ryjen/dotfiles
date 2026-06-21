{ ... }:
{
  imports = [
    ./headless.nix
  ];

  dotfiles.host.name = "wsl";
  dotfiles.host.wsl.enable = true;
  dotfiles.host.userSystemd.enable = false;
}
