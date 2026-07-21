{
  config,
  lib,
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
    };

    services.blueman.enable = true;
  };
}
