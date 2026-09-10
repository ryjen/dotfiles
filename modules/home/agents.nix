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

    # configctl owns the Hermes source-layer model. Home Manager publishes only
    # the read-only base layer under ~/.config/hermes, where configctl will
    # compose base + custom.d + local.yaml once parser-aware YAML composition is
    # write-enabled. The native runtime output (~/.hermes/config.yaml) is never
    # published here: base.yaml is a composition base, not a complete runtime
    # config, and publishing it directly clobbers the user's live provider/model
    # settings. Until configctl activation, the runtime output stays
    # user-managed.
    xdg.configFile."hermes/base.yaml" = lib.mkIf cfg.hermes.enable {
      source = ../../files/home/.config/hermes/base.yaml;
    };
    xdg.configFile."hermes/README.md" = lib.mkIf cfg.hermes.enable {
      source = ../../files/home/.config/hermes/README.md;
    };

    xdg.configFile."codex/adopted.d/00-managed.toml".source =
      ../../files/home/.config/codex/adopted.d/00-managed.toml;
    xdg.configFile."codex/custom.d/README.md".source =
      ../../files/home/.config/codex/custom.d/README.md;
    xdg.configFile."codex/README.md".source = ../../files/home/.config/codex/README.md;

  };
}
