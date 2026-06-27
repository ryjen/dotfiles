{
  hermes-agent,
  lib,
  pkgs,
  config,
  ...
}:
let
  hermesPackage = hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.dotfiles.agents.hermes.enable = lib.mkEnableOption "Hermes agent package and config";

  config = {
    home.packages = lib.optional config.dotfiles.agents.hermes.enable hermesPackage;

    home.file.".hermes/config.yaml" = lib.mkIf config.dotfiles.agents.hermes.enable {
      source = ../../files/home/.hermes/config.yaml;
    };

    xdg.configFile."codex/adopted.d/00-managed.toml".source = ../../files/home/.config/codex/adopted.d/00-managed.toml;
    xdg.configFile."codex/custom.d/README.md".source = ../../files/home/.config/codex/custom.d/README.md;
    xdg.configFile."codex/README.md".source = ../../files/home/.config/codex/README.md;

    home.file.".codex/rules/default.rules".source = ../../files/home/.codex/rules/default.rules;
  };
}
