{
  hermes-agent,
  lib,
  pkgs,
  config,
  ...
}:
let
  hermesPackage = hermes-agent.packages.${pkgs.system}.default;

  agentsUpdate = pkgs.writeShellApplication {
    name = "agents-update";
    runtimeInputs = with pkgs; [
      coreutils
      git
      jq
      rsync
    ];
    text = builtins.readFile ../../scripts/home/agents-update.sh;
  };

  codexBootstrapConfig = pkgs.writeShellApplication {
    name = "codex-bootstrap-config";
    runtimeInputs = with pkgs; [
      coreutils
    ];
    text = builtins.readFile ../../scripts/home/codex-bootstrap-config.sh;
  };
in
{
  options.dotfiles.agents.hermes.enable = lib.mkEnableOption "Hermes agent package and config";

  config = {
    home.packages = [
      agentsUpdate
    ]
    ++ lib.optional config.dotfiles.agents.hermes.enable hermesPackage;

    home.file.".agents/.skill-lock.json".source = ../../files/home/.agents/.skill-lock.json;
    home.file.".hermes/config.yaml" = lib.mkIf config.dotfiles.agents.hermes.enable {
      source = ../../files/home/.hermes/config.yaml;
    };

    xdg.configFile."codex/adopted.d/00-managed.conf".source = ../../files/home/.config/codex/adopted.d/00-managed.conf;
    xdg.configFile."codex/custom.d/.keep".source = ../../files/home/.config/codex/custom.d/.keep;
    xdg.configFile."codex/README.md".source = ../../files/home/.config/codex/README.md;

    home.activation.bootstrapCodexConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run ${lib.getExe codexBootstrapConfig}
    '';

    home.file.".codex/rules/default.rules".source = ../../files/home/.codex/rules/default.rules;
  };
}
