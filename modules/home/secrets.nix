{ config, ... }:
{
  sops = {
    defaultSopsFile = ../../secrets.yaml;
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    gnupg.home = "${config.home.homeDirectory}/.gnupg";

    secrets = {
      github_token = { };
      openai_api_key = { };
      anthropic_api_key = { };
    };
  };

  sops.templates."user-runtime-secrets.env".content = ''
    export GITHUB_TOKEN=${config.sops.placeholder.github_token}
    export OPENAI_API_KEY=${config.sops.placeholder.openai_api_key}
    export ANTHROPIC_API_KEY=${config.sops.placeholder.anthropic_api_key}
  '';

  home.sessionVariables = {
    GITHUB_TOKEN_PATH = config.sops.secrets.github_token.path;
    OPENAI_API_KEY_PATH = config.sops.secrets.openai_api_key.path;
    ANTHROPIC_API_KEY_PATH = config.sops.secrets.anthropic_api_key.path;
  };

  home.file.".config/zsh/config.d/10-user-runtime-secrets.zsh".text = ''
    if [ -r "${config.sops.templates."user-runtime-secrets.env".path}" ]; then
      source "${config.sops.templates."user-runtime-secrets.env".path}"
    fi
  '';
}
