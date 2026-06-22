{
  lib,
  pkgs,
  config,
  ...
}:
{
  options.dotfiles.graphical.keyring.enable =
    lib.mkEnableOption "graphical Secret Service credential storage";

  config = lib.mkIf config.dotfiles.graphical.keyring.enable {
    assertions = [
      {
        assertion = config.dotfiles.host.graphical.enable;
        message = "dotfiles.graphical.keyring.enable requires dotfiles.host.graphical.enable.";
      }
      {
        assertion = config.dotfiles.host.userSystemd.enable;
        message = "dotfiles.graphical.keyring.enable requires Home Manager user systemd support.";
      }
    ];

    home.packages = [
      pkgs.gnome-keyring
    ];

    services.gnome-keyring = {
      enable = true;
      components = [
        "secrets"
      ];
    };
  };
}
