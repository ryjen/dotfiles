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
  hermesRoot = ../../files/home/.config/hermes;
  hermesAdoptedDir = "${hermesRoot}/adopted.d";
  hermesAdoptedFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".toml" name) (
    builtins.readDir hermesAdoptedDir
  );
  hermesAdoptedConfigFiles = lib.mapAttrs' (name: _type: {
    name = "hermes/adopted.d/${name}";
    value = {
      source = "${hermesAdoptedDir}/${name}";
    };
  }) hermesAdoptedFiles;
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

  config = lib.mkMerge [
    {
      home.packages =
        lib.optional cfg.hermes.enable hermesPackage
        ++ lib.optional cfg.antigravity.enable cfg.antigravity.package;

      home.sessionVariables = lib.mkIf cfg.hermes.enable {
        HERMES_CONFIG = "${config.home.homeDirectory}/.hermes/config.toml";
      };

      xdg.configFile."codex/adopted.d/00-managed.toml".source =
        ../../files/home/.config/codex/adopted.d/00-managed.toml;
      xdg.configFile."codex/custom.d/README.md".source =
        ../../files/home/.config/codex/custom.d/README.md;
      xdg.configFile."codex/README.md".source = ../../files/home/.config/codex/README.md;
    }
    (lib.mkIf cfg.hermes.enable {
      xdg.configFile = hermesAdoptedConfigFiles // {
        "hermes/custom.d/README.md".source =
          ../../files/home/.config/hermes/custom.d/README.md;
        "hermes/README.md".source = ../../files/home/.config/hermes/README.md;
      };
    })
  ];
}
