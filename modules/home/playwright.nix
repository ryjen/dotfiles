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
  options.dotfiles.playwright.enable = lib.mkEnableOption "Nix-managed browser runtime for Playwright automation";

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.chromium
    ];

    home.sessionVariables = {
      # Let projects own their Playwright npm version while Nix owns the browser
      # executable. This avoids coupling project Playwright releases to the
      # browser revision bundled by nixpkgs's playwright-driver package.
      PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";

      # Project installs should not download Playwright-managed browser bundles
      # when a Nix-provided Chromium runtime is available.
      PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
    };
  };
}
