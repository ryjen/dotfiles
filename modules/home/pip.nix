{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.pip;
  pipGlobalBin = "${cfg.prefix}/bin";
in
{
  options.dotfiles.pip = {
    enable = lib.mkEnableOption "pip global tooling environment";

    prefix = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.local/share/pip";
      description = "User-writable pip global prefix.";
    };

    globalPackagesFile = lib.mkOption {
      type = lib.types.str;
      default = ".config/pip/global-packages.txt";
      description = "Home-relative path to the pip global package manifest.";
    };
  };

  config = lib.mkMerge [
    {
      dotfiles.pip.enable = lib.mkDefault (config.dotfiles.profiles.workstation.enable or false);
    }

    (lib.mkIf cfg.enable {
      home.packages = [ pkgs.uv ];

      home.sessionPath = [ pipGlobalBin ];

      home.file."${cfg.globalPackagesFile}".source = ../../files/home/.config/pip/global-packages.txt;

      home.activation.createPipGlobalPrefix = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${cfg.prefix}" "${pipGlobalBin}"
      '';
    })
  ];
}
