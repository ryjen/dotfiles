{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.codexDesktop;
in
{
  options.dotfiles.codexDesktop = {
    enable = lib.mkEnableOption "OpenAI ChatGPT desktop (including Codex) for Linux";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../../packages/chatgpt-linux/package.nix {
        # Use the official bundled Codex runtime. The separately managed CLI is
        # intentionally independent of the desktop application's release cycle.
        codex = null;
      };
      description = ''
        The pinned official ChatGPT Linux preview package. This local Nixpkgs
        backport can be replaced when the tracked stable channel supports Linux.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isLinux;
        message = "dotfiles.codexDesktop is supported only on Linux";
      }
    ];

    # The upstream package provides chatgpt and the desktop entry. No service,
    # background daemon, login hook or separate mutable installer is installed.
    home.packages = [ cfg.package ];
  };
}
