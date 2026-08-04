{
  config,
  lib,
  ops-cadence,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.opsCadence;
  package = cfg.package;
  careerOpsStateDir = cfg.careerops.stateDir;
  runtimePath = lib.makeBinPath [
    package
    pkgs.coreutils
    pkgs.git
    pkgs.nodejs
  ];
  credentialLoads =
    lib.optional (cfg.credentials.githubTokenFile != null)
      "github-token:${cfg.credentials.githubTokenFile}"
    ++ lib.optional (cfg.credentials.gmailAccessTokenFile != null)
      "gmail-access-token:${cfg.credentials.gmailAccessTokenFile}";
  credentialExports = ''
    ${lib.optionalString (cfg.credentials.githubTokenFile != null) ''
      export GITHUB_TOKEN="$(${pkgs.coreutils}/bin/cat "$CREDENTIALS_DIRECTORY/github-token")"
    ''}
    ${lib.optionalString (cfg.credentials.gmailAccessTokenFile != null) ''
      export GMAIL_ACCESS_TOKEN="$(${pkgs.coreutils}/bin/cat "$CREDENTIALS_DIRECTORY/gmail-access-token")"
    ''}
  '';
  mkOpsRunner = report:
    pkgs.writeShellScript "opsctl-${report}" ''
      set -euo pipefail
      umask 077
      ${credentialExports}
      exec ${package}/bin/opsctl run ${lib.escapeShellArg report}
    '';
  mkOpsService = report: {
    Unit = {
      Description = "opsctl ${report} report";
      Documentation = [
        "https://github.com/ryjen/ops-cadence"
        "https://github.com/ryjen/ops-cadence/blob/main/docs/timer-operations.md"
      ];
      After = [ "default.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${mkOpsRunner report}";
      Environment = [
        "HOME=%h"
        "XDG_CONFIG_HOME=%h/.config"
        "XDG_STATE_HOME=%h/.local/state"
        "PATH=${runtimePath}"
      ];
      UnsetEnvironment = [
        "AWS_ACCESS_KEY_ID"
        "AWS_SECRET_ACCESS_KEY"
        "AWS_SESSION_TOKEN"
        "GH_TOKEN"
        "GITHUB_TOKEN"
        "GITLAB_TOKEN"
        "GOOGLE_APPLICATION_CREDENTIALS"
        "GMAIL_ACCESS_TOKEN"
        "OPENAI_API_KEY"
        "SSH_AGENT_PID"
        "SSH_AUTH_SOCK"
      ];
      LoadCredential = credentialLoads;
      SuccessExitStatus = [ "75" ];
      TimeoutStartSec = cfg.timers.timeout;
      TimeoutStopSec = "30s";
      KillMode = "mixed";
      Restart = "no";
      UMask = "0077";
      Nice = 10;
      IOSchedulingClass = "idle";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      ReadWritePaths = [ "%h/.local/state/ops-cadence" ];
      RestrictSUIDSGID = true;
      LockPersonality = true;
      RestrictRealtime = true;
      StandardOutput = "journal";
      StandardError = "journal";
      SyslogIdentifier = "opsctl-${report}";
    };
  };
  mkOpsTimer = description: calendar: serviceName: {
    Unit.Description = description;
    Timer = {
      OnCalendar = calendar;
      Persistent = true;
      AccuracySec = cfg.timers.accuracy;
      RandomizedDelaySec = cfg.timers.randomizedDelay;
      Unit = "${serviceName}.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };
in
{
  options.dotfiles.opsCadence = {
    enable = lib.mkEnableOption "personal ops cadence runner";

    package = lib.mkOption {
      type = lib.types.package;
      default = ops-cadence.packages.${pkgs.stdenv.hostPlatform.system}.default;
      description = "ops-cadence package to install.";
    };

    careerops = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to consume local read-only CareerOps contracts.";
      };

      workflowsPath = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/.local/src/career-workflows";
        description = "Local career-workflows checkout containing the CareerOps automation CLI.";
      };

      stateDir = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/.local/state/careerops";
        description = "Directory containing minimized CareerOps JSON artifacts.";
      };
    };

    liveSources = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether timer runs may use bounded live source adapters.";
      };

      gmail = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to enable bounded Gmail ingestion.";
      };

      github = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to enable bounded GitHub ingestion.";
      };
    };

    credentials = {
      githubTokenFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Runtime path to a read-only GitHub token loaded through systemd credentials.";
      };

      gmailAccessTokenFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Runtime path to a short-lived Gmail access token loaded through systemd credentials.";
      };
    };

    timers = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to create user-level systemd timers for opsctl reports.";
      };

      timeout = lib.mkOption {
        type = lib.types.str;
        default = "15min";
        description = "Maximum runtime for each report service.";
      };

      accuracy = lib.mkOption {
        type = lib.types.str;
        default = "5min";
        description = "Systemd timer scheduling accuracy.";
      };

      randomizedDelay = lib.mkOption {
        type = lib.types.str;
        default = "5min";
        description = "Maximum randomized delay applied to each timer.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ package ];

    xdg.configFile."ops-cadence/config.toml".text = ''
      [state]
      backend = "memory"

      [llm]
      base_url = "http://127.0.0.1:8080/v1"
      model = "local"

      [sources.github]
      career_workflows = "ryjen/career-workflows"
      career_data = "ryjen/career-data"

      [sources.local_git]
      dubnium = "${config.home.homeDirectory}/.local/src/dubnium"
      dotfiles = "${config.home.homeDirectory}/.local/src/dubnium/external/dotfiles"

      [sources.live]
      enabled = ${lib.boolToString cfg.liveSources.enable}
      gmail = ${lib.boolToString cfg.liveSources.gmail}
      github = ${lib.boolToString cfg.liveSources.github}
      gmail_lookback_days = 3
      gmail_result_limit = 50
      github_result_limit = 25

      [careerops]
      enabled = ${lib.boolToString cfg.careerops.enable}
      workflows_path = "${cfg.careerops.workflowsPath}"
      tracker_snapshot_path = "${careerOpsStateDir}/application-state.json"
      discovery_bundle_path = "${careerOpsStateDir}/discovery-candidates.json"
      capacity_path = "${careerOpsStateDir}/execution-capacity.json"
      follow_up_queue_path = "${careerOpsStateDir}/follow-up-queue.json"
      issue_priorities_path = "${careerOpsStateDir}/issue-priorities.json"
      blockers_path = "${careerOpsStateDir}/blockers.json"
      timeout_seconds = 30
    '';

    systemd.user.tmpfiles.rules = lib.mkIf (cfg.timers.enable && config.dotfiles.host.userSystemd.enable) [
      "d %h/.local/state/ops-cadence 0700 - - -"
    ];

    systemd.user.services = lib.mkIf (cfg.timers.enable && config.dotfiles.host.userSystemd.enable) {
      opsctl-career-intelligence = mkOpsService "career-intelligence";
      opsctl-engineering-portfolio = mkOpsService "engineering-portfolio";
      opsctl-weekly-review = mkOpsService "weekly-review";
    };

    systemd.user.timers = lib.mkIf (cfg.timers.enable && config.dotfiles.host.userSystemd.enable) {
      opsctl-career-intelligence = mkOpsTimer "Daily Career Intelligence" "*-*-* 08:00:00" "opsctl-career-intelligence";
      opsctl-engineering-portfolio = mkOpsTimer "Weekly Engineering Portfolio Review" "Mon *-*-* 09:30:00" "opsctl-engineering-portfolio";
      opsctl-weekly-review = mkOpsTimer "Weekly Project Review" "Fri *-*-* 16:30:00" "opsctl-weekly-review";
    };
  };
}
