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

    hermes.dashboard = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.hermes.enable;
        description = "Whether to run the Hermes dashboard as a user systemd service.";
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Host for the dashboard listener.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 9119;
        description = "Port for the dashboard listener.";
      };
    };

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
    xdg.configFile = {
      "hermes/base.yaml" = lib.mkIf cfg.hermes.enable {
        source = ../../files/home/.config/hermes/base.yaml;
      };
      "hermes/README.md" = lib.mkIf cfg.hermes.enable {
        source = ../../files/home/.config/hermes/README.md;
      };

      "codex/adopted.d/00-managed.toml".source = ../../files/home/.config/codex/adopted.d/00-managed.toml;
      "codex/custom.d/README.md".source = ../../files/home/.config/codex/custom.d/README.md;
      "codex/README.md".source = ../../files/home/.config/codex/README.md;
    };

    systemd.user.services.hermes-dashboard = lib.mkIf cfg.hermes.dashboard.enable {
      Unit = {
        Description = "Hermes Agent Dashboard (web UI)";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
        # Bound the restart loop. A previous value of 0 disabled start
        # limiting entirely, so a permanently-failing dashboard retried every
        # few seconds forever: 12114 restarts and ~220k journal lines from a
        # fatal config error. With a finite window systemd gives up and holds
        # the unit in `failed` instead of burning a core continuously.
        StartLimitIntervalSec = "300";
        StartLimitBurst = 5;
      };

      Service = {
        Type = "simple";
        ExecStart =
          "${hermesPackage}/bin/hermes dashboard"
          + " --host ${cfg.hermes.dashboard.host}"
          + " --port ${toString cfg.hermes.dashboard.port}"
          + " --no-open"
          + " --skip-build";
        WorkingDirectory = "${config.home.homeDirectory}/.hermes";
        Environment = [
          "HOME=${config.home.homeDirectory}"
          "HERMES_HOME=%h/.hermes"
        ];
        EnvironmentFile = [ "-/run/secrets/hermes-env" ];
        Restart = "always";
        RestartSec = "5s";
        RestartForceExitStatus = [ "75" ];
        KillMode = "mixed";
        KillSignal = "SIGTERM";
        TimeoutStopSec = "60";
        StandardOutput = "journal";
        StandardError = "journal";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
