{
  ...
}:
{
  imports = [
    ./fonts.nix
    ./motd.nix
    ./podman.nix
    ./shell.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  networking.networkmanager.enable = true;
  services.openssh.enable = true;
}
