{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dubnium.bluetooth;
in
{
  options.dubnium.bluetooth.enable = lib.mkEnableOption "Bluetooth device support";

  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Experimental = true;
        };
        Policy = {
          AutoEnable = true;
        };
      };
    };

    services.blueman.enable = true;

    environment.systemPackages = [ pkgs.bluez ];
  };
}
