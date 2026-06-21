{ ... }:
{
  imports = [
    ./headless.nix
  ];

  dotfiles.host.name = "verify";
}
