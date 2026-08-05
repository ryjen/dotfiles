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
  professionalContextPath =
    if cfg.careerops.professionalContextSnapshotPath == null then
      "${careerOpsStateDir}/professional-context.v1.json"
    else
      cfg.careerops.professionalContextSnapshotPath;
  githubCredentialEnabled = cfg.liveSources.enable && cfg.liveSources.github;
  gmailCredentialEnabled = cfg.liveSources.enable && cfg.liveSources.gmail;
  credentialPathSafe =
    value:
    value == null
    || (
      (lib.hasPrefix "/" value || lib.hasPrefix "%h/" value)
      && !lib.hasPrefix "/nix/store/" value
      && !lib.hasInfix ":" value
      && !lib.hasInfix "\n" value
    );
  loopbackUrl =
    value:
    lib.any (prefix: lib.hasPrefix prefix value) [
      "http://127.0.0.1:"
      "http://localhost:"
      "http://[::1]:"
      "https://127.0.0.1:"
      "https://localhost:"
      "https://[::1]:"
    ]
    && !lib.hasInfix "\n" value;
  scheduleIdSafe = value: builtins.match "^[A-Za-z0-9._:-]{1,200}$" value != null;
  runtimePath = lib.makeBinPath [
    package
    pkgs.coreutils
    pkgs.git
    pkgs.nodejs
  ];
  credentialLoads =
    lib.optional (githubCredentialEnabled && cfg.credentials.githubTokenFile != null)
      "github-token:${cfg.credentials.githubTokenFile}"
    ++ lib.optional (gmailCredentialEnabled && cfg.credentials.gmailAccessTokenFile != null)
      "gmail-access-token:${cfg.credentials.gmailAccessTokenFile}";
  credentialExports = ''
    ${lib.optionalString githubCredentialEnabled ''
      github_credential="$CREDENTIALS_DIRECTORY/github-token"
      if [ ! -s "$github_credential" ] || [ "$(${pkgs.coreutils}/bin/wc -c < "$github_credential")" -gt 8192 ]; then
        echo "opsctl credential validation failed: github-token" >&2
        exit 78
      fi
      export GITHUB_TOKEN="$(${pkgs.coreutils}/bin/cat "$github_credential")"
      unset github_credential
    ''}
    ${lib.optionalString gmailCredentialEnabled ''
      gmail_credential="$CREDENTIALS_DIRECTORY/gmail-access-token"
      if [ ! -s "$gmail_credential" ] || [ "$(${pkgs.coreutils}/bin/wc -c < "$gmail_credential")" -gt 8192 ]; then
        echo "opsctl credential validation failed: gmail-access-token" >&2
        exit 78
      fi
      export GMAIL_ACCESS_TOKEN="$(${pkgs.coreutils}/bin/cat "$gmail_credential")"
      unset gmail_credential
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
        "https://github.com/ryjen/ops-cadence/blob/main/docs/security-boundaries.md"
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
        "PYTHONNOUSERSITE=1"
      ];
      UnsetEnvironment = [
        "ANTHROPIC_API_KEY"
        "AWS_ACCESS_KEY_ID"
        "AWS_SECRET_ACCESS_KEY"
        "AWS_SESSION_TOKEN"
        "CLOUDFLARE_API_TOKEN"
        "DOCKER_CONFIG"
        "GH_TOKEN"
        "GITHUB_TOKEN"
        "GITLAB_TOKEN"
        "GOOGLE_APPLICATION_CREDENTIALS"
        "GOOGLE_API_KEY"
        "GMAIL_ACCESS_TOKEN"
        "HF_TOKEN"
        "HUGGING_FACE_HUB_TOKEN"
        "KUBECONFIG"
        "NPM_TOKEN"
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
    }
    // lib.optionalAttrs (cfg.careerops.enable && report == "career-intelligence") {
      ExecStartPre = "${package}/bin/opsctl doctor --probe --json";
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

      professionalContextSnapshotPath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Absolute path to the minimized professional-context snapshot; null uses stateDir/professional-context.v1.json.";
      };
    };

    platform = {
      memory = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to use the loopback Dubnium memory API for minimized semantic context.";
        };
        baseUrl = lib.mkOption {
          type = lib.types.str;
          default = "http://127.0.0.1:8090";
          description = "Loopback Dubnium memory API base URL.";
        };
        timeoutSeconds = lib.mkOption {
          type = lib.types.ints.positive;
          default = 10;
          description = "Dubnium memory API timeout in seconds.";
        };
        scope = lib.mkOption {
          type = lib.types.str;
          default = "workflow:ops-cadence";
          description = "Bounded semantic memory scope.";
        };
      };

      llm = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to use the governed loopback Dubnium LLM gateway.";
        };
        baseUrl = lib.mkOption {
          type = lib.types.str;
          default = "http://127.0.0.1:8080/v1";
          description = "Loopback Dubnium LLM gateway base URL.";
        };
        model = lib.mkOption {
          type = lib.types.str;
          default = "supervisor";
          description = "Governed logical LLM alias.";
        };
        contractVersion = lib.mkOption {
          type = lib.types.str;
          default = "dubnium.llm-gateway.v1";
          description = "Expected governed LLM gateway contract version.";
        };
        timeoutSeconds = lib.mkOption {
          type = lib.types.ints.positive;
          default = 60;
          description = "Dubnium LLM gateway timeout in seconds.";
        };
      };

      scheduler = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to use declared Dubnium schedules instead of direct Home Manager timers.";
        };
        baseUrl = lib.mkOption {
          type = lib.types.str;
          default = "http://127.0.0.1:8091";
          description = "Loopback Dubnium scheduler API base URL.";
        };
        timeoutSeconds = lib.mkOption {
          type = lib.types.ints.positive;
          default = 10;
          description = "Dubnium scheduler API timeout in seconds.";
        };
        schedules = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = {
            career_intelligence = "ops-career-intelligence";
            engineering_portfolio = "ops-engineering-portfolio";
            weekly_review = "ops-weekly-review";
          };
          description = "Allowlisted logical report names mapped to declaratively managed Dubnium schedule IDs.";
        };
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
        description = "Whether to create transitional user-level systemd timers for opsctl reports.";
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
    assertions = [
      {
        assertion = !cfg.liveSources.gmail || cfg.liveSources.enable;
        message = "dotfiles.opsCadence.liveSources.gmail requires liveSources.enable.";
      }
      {
        assertion = !cfg.liveSources.github || cfg.liveSources.enable;
        message = "dotfiles.opsCadence.liveSources.github requires liveSources.enable.";
      }
      {
        assertion = !cfg.liveSources.enable || cfg.liveSources.gmail || cfg.liveSources.github;
        message = "dotfiles.opsCadence.liveSources.enable requires at least one enabled live source.";
      }
      {
        assertion = !githubCredentialEnabled || cfg.credentials.githubTokenFile != null;
        message = "Enabled GitHub ingestion requires credentials.githubTokenFile.";
      }
      {
        assertion = !gmailCredentialEnabled || cfg.credentials.gmailAccessTokenFile != null;
        message = "Enabled Gmail ingestion requires credentials.gmailAccessTokenFile.";
      }
      {
        assertion = credentialPathSafe cfg.credentials.githubTokenFile;
        message = "credentials.githubTokenFile must be an absolute or %h-relative runtime path outside the Nix store, without colon or newline characters.";
      }
      {
        assertion = credentialPathSafe cfg.credentials.gmailAccessTokenFile;
        message = "credentials.gmailAccessTokenFile must be an absolute or %h-relative runtime path outside the Nix store, without colon or newline characters.";
      }
      {
        assertion = lib.hasPrefix "/" cfg.careerops.workflowsPath;
        message = "careerops.workflowsPath must be absolute.";
      }
      {
        assertion = lib.hasPrefix "/" cfg.careerops.stateDir;
        message = "careerops.stateDir must be absolute.";
      }
      {
        assertion = lib.hasPrefix "/" professionalContextPath;
        message = "careerops professional-context snapshot path must be absolute.";
      }
      {
        assertion = loopbackUrl cfg.platform.memory.baseUrl;
        message = "platform.memory.baseUrl must be an explicit loopback HTTP(S) URL.";
      }
      {
        assertion = loopbackUrl cfg.platform.llm.baseUrl;
        message = "platform.llm.baseUrl must be an explicit loopback HTTP(S) URL.";
      }
      {
        assertion = loopbackUrl cfg.platform.scheduler.baseUrl;
        message = "platform.scheduler.baseUrl must be an explicit loopback HTTP(S) URL.";
      }
      {
        assertion = builtins.match "^[A-Za-z0-9._:-]{1,200}$" cfg.platform.llm.model != null;
        message = "platform.llm.model must be a bounded logical alias.";
      }
      {
        assertion = builtins.match "^[A-Za-z0-9._:-]{1,200}$" cfg.platform.llm.contractVersion != null;
        message = "platform.llm.contractVersion must be a bounded contract identifier.";
      }
      {
        assertion = builtins.match "^[A-Za-z0-9._:-]{1,200}$" cfg.platform.memory.scope != null;
        message = "platform.memory.scope must be a bounded scope identifier.";
      }
      {
        assertion = lib.all scheduleIdSafe (lib.attrValues cfg.platform.scheduler.schedules);
        message = "Every platform.scheduler schedule ID must use the bounded allowlisted identifier format.";
      }
      {
        assertion = !(cfg.timers.enable && cfg.platform.scheduler.enable);
        message = "Direct Home Manager timers and the Dubnium scheduler cannot both own durable ops-cadence scheduling.";
      }
    ];

    home.packages = [ package ];

    xdg.configFile."ops-cadence/config.toml".text = ''
      [state]
      backend = "sqlite"
      sqlite_path = "${config.home.homeDirectory}/.local/state/ops-cadence/ops.sqlite3"

      [platform.memory]
      enabled = ${lib.boolToString cfg.platform.memory.enable}
      base_url = "${cfg.platform.memory.baseUrl}"
      timeout_seconds = ${toString cfg.platform.memory.timeoutSeconds}
      scope = "${cfg.platform.memory.scope}"

      [platform.llm]
      enabled = ${lib.boolToString cfg.platform.llm.enable}
      base_url = "${cfg.platform.llm.baseUrl}"
      model = "${cfg.platform.llm.model}"
      contract_version = "${cfg.platform.llm.contractVersion}"
      timeout_seconds = ${toString cfg.platform.llm.timeoutSeconds}

      [platform.scheduler]
      enabled = ${lib.boolToString cfg.platform.scheduler.enable}
      base_url = "${cfg.platform.scheduler.baseUrl}"
      timeout_seconds = ${toString cfg.platform.scheduler.timeoutSeconds}

      [platform.scheduler.schedules]
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: scheduleId: ''${name} = "${scheduleId}"'') cfg.platform.scheduler.schedules
      )}

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
      professional_context_snapshot_path = "${professionalContextPath}"
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
