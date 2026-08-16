{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.playwright;
in
{
  options.dotfiles.playwright.enable = lib.mkEnableOption "Nix-managed Playwright browser automation tooling";

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.playwright-test
      pkgs.playwright-driver.browsers
    ];

    home.sessionVariables = {
      # Keep Playwright's browser runtime immutable and Nix-owned. Do not run
      # `playwright install`/`npx playwright install` on NixOS; those commands
      # attempt to populate a mutable browser cache with non-Nix binaries.
      PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
      PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
      PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
    };
  };
}
