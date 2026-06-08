{ config, lib, pkgs, ... }:

let
  cfg = config.ryjen.ai.plano;
in
{
  options.ryjen.ai.plano = {
    enable = lib.mkEnableOption "user-level Plano client configuration";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Optional Plano package to install when available in nixpkgs/overlay. Leave null when installed by uv or another tool manager.";
    };

    configFile = lib.mkOption {
      type = lib.types.str;
      default = "planoai/dubnium.yaml";
      description = "XDG config path for the generated Dubnium-oriented Plano config.";
    };

    listenerAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
    };

    listenerPort = lib.mkOption {
      type = lib.types.port;
      default = 12000;
    };

    localModel = lib.mkOption {
      type = lib.types.str;
      default = "openai/qwen2.5-coder-14b-instruct";
    };

    localBaseUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:8000/v1";
      description = "OpenAI-compatible local model endpoint. Dubnium should usually provide this via vLLM or Ollama.";
    };

    enableOpenAI = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    openAIModel = lib.mkOption {
      type = lib.types.str;
      default = "openai/gpt-4o-mini";
    };

    enableAnthropic = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    anthropicModel = lib.mkOption {
      type = lib.types.str;
      default = "anthropic/claude-3-5-sonnet";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optional (cfg.package != null) cfg.package;

    xdg.configFile.${cfg.configFile}.text = ''
      version: v0.4.0

      listeners:
        - name: egress_traffic
          type: model
          address: ${cfg.listenerAddress}
          port: ${toString cfg.listenerPort}
          timeout: 120s

      model_providers:
        - model: ${cfg.localModel}
          access_key: EMPTY
          base_url: ${cfg.localBaseUrl}
          default: true
      ${lib.optionalString cfg.enableOpenAI ''
        - model: ${cfg.openAIModel}
          access_key: "$OPENAI_API_KEY"
      ''}
      ${lib.optionalString cfg.enableAnthropic ''
        - model: ${cfg.anthropicModel}
          access_key: "$ANTHROPIC_API_KEY"
      ''}

      model_aliases:
        local-code:
          target: qwen2.5-coder-14b-instruct
        fast-local:
          target: qwen2.5-coder-14b-instruct

      routing_preferences:
        - name: local code work
          description: code understanding, code generation, refactoring, and repo analysis that should prefer local inference
          models:
            - ${cfg.localModel}
    '';

    home.file.".local/bin/plano-dubnium" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        CONFIG_FILE="''${PLANO_CONFIG_FILE:-''${XDG_CONFIG_HOME:-$HOME/.config}/${cfg.configFile}}"

        case "''${1:-up}" in
          up)
            exec planoai up "$CONFIG_FILE"
            ;;
          build)
            exec planoai build "$CONFIG_FILE"
            ;;
          logs)
            exec planoai logs --follow
            ;;
          config)
            printf '%s\n' "$CONFIG_FILE"
            ;;
          *)
            exec planoai "$@"
            ;;
        esac
      '';
    };
  };
}
