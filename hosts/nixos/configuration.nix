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
