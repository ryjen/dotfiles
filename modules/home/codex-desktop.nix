{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.codexDesktop;
  desktopPackage = pkgs.callPackage ../../packages/chatgpt-linux/package.nix {
    # The desktop owns its bundled Codex runtime; do not replace the
    # independently managed system CLI or couple the two release cycles.
    codex = null;
  };
in
{
  options.dotfiles.codexDesktop.enable = lib.mkEnableOption "ChatGPT desktop with Codex on Linux";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isLinux;
        message = "dotfiles.codexDesktop is supported only on Linux";
      }
    ];

    # The package provides the chatgpt binary and desktop entry, without a
    # systemd service, autostart or a mutable second installation method.
    home.packages = [ desktopPackage ];

    # Preserve the existing chatgpt.desktop Chromium profile entry.
    # A distinct desktop ID makes the native Codex app discoverable via SUPER+R
    # without colliding with the browser module or changing browser defaults.
    xdg.desktopEntries.codex-desktop = {
      name = "Codex Desktop";
      genericName = "Codex desktop workspace";
      comment = "ChatGPT desktop with integrated Codex";
      exec = "${desktopPackage}/bin/chatgpt %U";
      icon = "chatgpt";
      terminal = false;
      startupNotify = true;
      categories = [
        "Development"
        "Utility"
      ];
      settings.Keywords = "Codex;ChatGPT;OpenAI;AI;";
    };
  };
}
