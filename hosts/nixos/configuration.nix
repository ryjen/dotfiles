{
  pkgs,
  username,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/default.nix
  ];

  networking.hostName = "nixos";
  time.timeZone = "America/Vancouver";
  i18n.defaultLocale = "en_US.UTF-8";

  # This host is evaluated by CI as a generic NixOS verification target.
  # It is not an installer image and should not try to install GRUB to a
  # real disk during evaluation.
  boot.loader.grub.enable = false;

  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.zsh;
  };

  system.stateVersion = "25.05";
}
