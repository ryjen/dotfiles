{
  ...
}:
{
  imports = [
    ./fonts.nix
    ./shell.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.networkmanager.enable = true;
  services.openssh.enable = true;
}
