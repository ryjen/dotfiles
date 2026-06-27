{
  antigravity-nix,
  hermes-agent,
  lib,
  pkgs,
  config,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  hermesPackage = hermes-agent.packages.${system}.default;
  antigravityPackage = antigravity-nix.packages.${system}.google-antigravity-cli;
  cfg = config.dotfiles.agents;
in
{
  options.dotfiles.agents = {
    hermes.enable = lib.mkEnableOption "Hermes agent package and config";

    antigravity = {
      enable = lib.mkEnableOption "Google Antigravity CLI";

      package = lib.mkOption {
        type = lib.types.package;
        default = antigravityPackage;
        description = "Google Antigravity CLI package to install.";
      };
    };
  };

  config = {
    home.packages =
      lib.optional cfg.hermes.enable hermesPackage
      ++ lib.optional cfg.antigravity.enable cfg.antigravity.package;

    home.file.".hermes/config.yaml" = lib.mkIf cfg.hermes.enable {
      source = ../../files/home/.hermes/config.yaml;
    };

    xdg.configFile."codex/adopted.d/00-managed.toml".source =
      ../../files/home/.config/codex/adopted.d/00-managed.toml;
    xdg.configFile."codex/custom.d/README.md".source =
      ../../files/home/.config/codex/custom.d/README.md;
    xdg.configFile."codex/README.md".source = ../../files/home/.config/codex/README.md;

  };
}
