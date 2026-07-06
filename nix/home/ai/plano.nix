{
  config,
  lib,
  ...
}:

let
  cfg = config.ryjen.ai.plano;
in
{
  options.ryjen.ai.plano = {
    enable = lib.mkEnableOption "user-level Plano client configuration";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Optional Plano package to install when available in nixpkgs/overlay. Leave null when installed by uv or another tool manager.";
    };

    configFile = lib.mkOption {
      type = lib.types.str;
      default = "planoai/dubnium.yaml";
      description = "XDG config path for the static Dubnium-oriented Plano config.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optional (cfg.package != null) cfg.package;

    xdg.configFile.${cfg.configFile}.source = ../../../files/home/.config/planoai/dubnium.yaml;
  };
}
