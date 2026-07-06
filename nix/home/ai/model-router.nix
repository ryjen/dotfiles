{
  config,
  lib,
  ...
}:

let
  cfg = config.ryjen.ai.model-router;
in
{
  options.ryjen.ai.model-router = {
    enable = lib.mkEnableOption "user-level model-router policy/profile configuration";
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."model-router/profiles/local-first-dev.yaml".source =
      ../../../files/home/.config/model-router/profiles/local-first-dev.yaml;

    home.sessionVariables = {
      MODEL_ROUTER_PROFILE = "local-first-dev";
      MODEL_ROUTER_CONFIG_HOME = "${config.xdg.configHome}/model-router";
      MODEL_ROUTER_STATE_HOME = "${config.xdg.stateHome}/model-router";
      MODEL_ROUTER_LEDGER = "${config.xdg.stateHome}/model-router/route-decisions.jsonl";
      PLANO_BASE_URL = "http://127.0.0.1:12000";
      OPENAI_BASE_URL = "http://127.0.0.1:12000/v1";
    };
  };
}
