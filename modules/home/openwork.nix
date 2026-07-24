{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.openwork;
  openwork = pkgs.callPackage ../../packages/openwork.nix { };
in
{
  options.dotfiles.openwork.enable = lib.mkEnableOption "OpenWork desktop application";

  config = lib.mkIf cfg.enable {
    home.packages = [ openwork ];

    xdg.desktopEntries.openwork = {
      name = "OpenWork";
      genericName = "AI workflow desktop";
      comment = "Run and share AI workflows";
      exec = "openwork %U";
      icon = "applications-development";
      terminal = false;
      startupNotify = true;
      categories = [
        "Development"
        "Utility"
      ];
      mimeType = [ "x-scheme-handler/openwork" ];
      settings.StartupWMClass = "OpenWork";
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications."x-scheme-handler/openwork" = "openwork.desktop";
    };
  };
}
