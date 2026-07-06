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
  mkOpsService = report: {
    Unit = {
      Description = "opsctl ${report} report";
      Documentation = [ "https://github.com/ryjen/ops-cadence" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${package}/bin/opsctl run ${report}";
    };
  };
  mkOpsTimer = description: calendar: serviceName: {
    Unit.Description = description;
    Timer = {
      OnCalendar = calendar;
      Persistent = true;
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

    timers.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to create user-level systemd timers for opsctl reports.";
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
    '';

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
