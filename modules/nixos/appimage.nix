{
  config,
  lib,
  ...
}:
let
  cfg = config.dubnium.appimage;
in
{
  options.dubnium.appimage.enable = lib.mkEnableOption "AppImage runtime support";

  config = lib.mkIf cfg.enable {
    programs.appimage = {
      enable = true;
      binfmt = true;
    };
  };
}
