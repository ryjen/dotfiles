{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.uv;
  uvBin = "${config.home.homeDirectory}/.local/bin";
in
{
  options.dotfiles.uv = {
    enable = lib.mkEnableOption "uv isolated Python tool environment";

    toolsFile = lib.mkOption {
      type = lib.types.str;
      default = ".config/uv/tools.toml";
      description = "Home-relative path to the uv tool manifest.";
    };
  };

  config = lib.mkMerge [
    {
      dotfiles.uv.enable = lib.mkDefault (config.dotfiles.profiles.workstation.enable or false);
    }

    (lib.mkIf cfg.enable {
      home.packages = [ pkgs.uv ];
      home.sessionPath = [ uvBin ];

      home.file."${cfg.toolsFile}".source = ../../files/home/.config/uv/tools.toml;

      home.activation.createUvToolBin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${uvBin}"
      '';
    })
  ];
}
