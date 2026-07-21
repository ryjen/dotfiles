{
  config,
  lib,
  ...
}:
let
  cfg = config.dubnium.audio;
in
{
  options.dubnium.audio.enable = lib.mkEnableOption "PipeWire desktop audio support";

  config = lib.mkIf cfg.enable {
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
