{
  ...
}:
{
  imports = [
    ./appimage.nix
    ./audio.nix
    ./bluetooth.nix
    ./fonts.nix
    ./maintenance.nix
    ./motd.nix
    ./podman.nix
    ./shell.nix
    ./syncthing.nix
    ./unreal-storage.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  networking.networkmanager.enable = true;
  services.openssh.enable = true;
}
