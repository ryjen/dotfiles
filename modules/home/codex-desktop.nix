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

    # Home-level .desktop ID overrides any bundled entry from the .deb.
    # This guarantees a Nix-store executable path and makes Codex searchable
    # through the existing SUPER+R XDG application launcher.
    xdg.desktopEntries.chatgpt = {
      name = "ChatGPT (Codex)";
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
    };
  };
}
