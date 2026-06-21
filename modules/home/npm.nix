{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.npm;
  npmGlobalBin = "${cfg.prefix}/bin";
in
{
  options.dotfiles.npm = {
    enable = lib.mkEnableOption "npm global tooling environment";

    prefix = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.local/share/npm";
      description = "User-writable npm global prefix.";
    };

    globalPackagesFile = lib.mkOption {
      type = lib.types.str;
      default = ".config/npm/global-packages.txt";
      description = "Home-relative path to the npm global package manifest.";
    };
  };

  config = lib.mkMerge [
    {
      dotfiles.npm.enable = lib.mkDefault (config.dotfiles.profiles.workstation.enable or false);
    }

    (lib.mkIf cfg.enable {
      home.packages = [ pkgs.nodejs ];
      home.sessionPath = [ npmGlobalBin ];

      home.file.".npmrc".text = ''
        # Managed by Home Manager.
        # Keep npm authentication and registry-specific local state out of this file.
        prefix=${cfg.prefix}
      '';

      home.file."${cfg.globalPackagesFile}".source = ../../files/home/.config/npm/global-packages.txt;

      home.activation.createNpmGlobalPrefix = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${cfg.prefix}" "${npmGlobalBin}"
      '';
    })
  ];
}
