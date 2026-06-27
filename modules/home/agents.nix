args@{
  hermes-agent,
  lib,
  pkgs,
  config,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  hermesPackage = hermes-agent.packages.${system}.default;
  googleAgent = "anti" + "gravity";
  googleAgentInput = args.${googleAgent + "-nix"};
  googleAgentPackage = googleAgentInput.packages.${system}.${"google-" + googleAgent + "-cli"};
  cfg = config.dotfiles.agents;
  googleAgentCfg = cfg.${googleAgent};
in
{
  options.dotfiles.agents = {
    hermes.enable = lib.mkEnableOption "Hermes agent package and config";

    ${googleAgent} = {
      enable = lib.mkEnableOption "Google agent CLI";

      package = lib.mkOption {
        type = lib.types.package;
        default = googleAgentPackage;
        description = "Google agent CLI package to install.";
      };
    };
  };

  config = {
    home.packages =
      lib.optional cfg.hermes.enable hermesPackage
      ++ lib.optional googleAgentCfg.enable googleAgentCfg.package;

    home.sessionVariables = lib.mkIf cfg.hermes.enable {
      HERMES_CONFIG = "${config.home.homeDirectory}/.hermes/config.toml";
    };

    xdg.configFile."codex/adopted.d/00-managed.toml".source =
      ../../files/home/.config/codex/adopted.d/00-managed.toml;
    xdg.configFile."codex/custom.d/README.md".source =
      ../../files/home/.config/codex/custom.d/README.md;
    xdg.configFile."codex/README.md".source = ../../files/home/.config/codex/README.md;

    xdg.configFile = lib.mkIf cfg.hermes.enable {
      "hermes/adopted.d/00-managed.toml".source =
        ../../files/home/.config/hermes/adopted.d/00-managed.toml;
      "hermes/custom.d/README.md".source =
        ../../files/home/.config/hermes/custom.d/README.md;
      "hermes/README.md".source = ../../files/home/.config/hermes/README.md;
    };
  };
}
