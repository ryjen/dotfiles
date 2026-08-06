{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.headroom;
in
{
  options.dotfiles.headroom = {
    proxy = {
      enable = lib.mkEnableOption "Headroom proxy user service";

      port = lib.mkOption {
        type = lib.types.port;
        default = 8787;
        description = "Port for the Headroom proxy.";
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Host address for the Headroom proxy.";
      };

      package = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/.local/libexec/headroom-proxy";
        description = "Path to the Headroom proxy launcher. The launcher prefers uv tool-installed Headroom and falls back to the legacy pip global during migration.";
      };
    };
  };

  config = lib.mkIf cfg.proxy.enable {
    home.file.".local/libexec/headroom-proxy" = {
      source = ../../files/home/.local/libexec/headroom-proxy;
      executable = true;
    };

    systemd.user.services.headroom-proxy = {
      Unit = {
        Description = "Headroom context compression proxy";
        Documentation = "https://headroom-docs.vercel.app";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${cfg.proxy.package} --host ${cfg.proxy.host} --port ${toString cfg.proxy.port} --backend litellm-opencode";
        Restart = "always";
        RestartSec = "5s";
        Environment = [
          "PATH=%h/.local/bin:%h/.local/share/pip/bin:%h/.venv/bin"
          "LD_LIBRARY_PATH=${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}"
          "HEADROOM_BACKEND=litellm-opencode"
          "HEADROOM_ANYLLM_PROVIDER=opencode"
          "HEADROOM_ANTHROPIC_API_URL=http://127.0.0.1:8000/v1"
          "HEADROOM_OPENAI_API_URL=http://127.0.0.1:8000/v1"
          "HEADROOM_REGION=ca-central-1"
          "HEADROOM_REQUEST_TIMEOUT=300"
          "HEADROOM_MODE=token"
          "HEADROOM_OPTIMIZATION_ENABLED=true"
          "HEADROOM_CODE_AWARE_ENABLED=1"
          "HEADROOM_MEMORY=true"
          "HEADROOM_SUBSCRIPTION_POLL_INTERVAL=300"
          "HEADROOM_COMPRESSION_MAX_WORKERS=4"
          "HEADROOM_LOSSLESS=1"
          "HEADROOM_NO_CCR_PROACTIVE_EXPANSION=1"
          "HEADROOM_BUDGET=10.0"
          "HEADROOM_BUDGET_PERIOD=daily"
          "HEADROOM_TELEMETRY=on"
          "HEADROOM_LOG_FILE=%h/.headroom/logs/proxy.log"
          "HEADROOM_LOG_MESSAGES=true"
          "HEADROOM_PROTECT_TOOL_RESULTS=bash,WebFetch"
          "HEADROOM_RPM=60"
          "HEADROOM_TPM=100000"
          "HEADROOM_ENABLE_EMBEDDING_SERVER=true"
          "HEADROOM_CODE_GRAPH=true"
          "HEADROOM_NO_READ_LIFECYCLE=1"
          "HEADROOM_NO_MEMORY_TOOLS=1"
          "HEADROOM_NO_LEARN=1"
          "HEADROOM_NO_SUBSCRIPTION_TRACKING=1"
          "HEADROOM_NO_TELEMETRY=1"
          "HEADROOM_NO_CC_R=1"
          "HEADROOM_MIN_EVIDENCE=1"
        ];
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
