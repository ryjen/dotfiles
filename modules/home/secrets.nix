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
      ssh_authorized_keys = { };
      gpg_default_key = { };
      gpg_keys = { };
    };
  };

  sops.templates."user-runtime-secrets.env".content = ''
    export GITHUB_TOKEN=${config.sops.placeholder.github_token}
    export OPENAI_API_KEY=${config.sops.placeholder.openai_api_key}
    export ANTHROPIC_API_KEY=${config.sops.placeholder.anthropic_api_key}
    export SSH_AUTHORIZED_KEYS_PATH=${config.sops.placeholder.ssh_authorized_keys}
    export GPG_DEFAULT_KEY_PLACEHOLDER=${config.sops.placeholder.gpg_default_key}
    export GPG_KEYS_PLACEHOLDER=${config.sops.placeholder.gpg_keys}
  '';

  home.sessionVariables = {
    GITHUB_TOKEN_PATH = config.sops.secrets.github_token.path;
    OPENAI_API_KEY_PATH = config.sops.secrets.openai_api_key.path;
    ANTHROPIC_API_KEY_PATH = config.sops.secrets.anthropic_api_key.path;
    SSH_AUTHORIZED_KEYS_PATH = config.sops.secrets.ssh_authorized_keys.path;
    GPG_DEFAULT_KEY_PATH = config.sops.secrets.gpg_default_key.path;
    GPG_KEYS_PATH = config.sops.secrets.gpg_keys.path;
  };

  home.file.".config/zsh/config.d/10-user-runtime-secrets.zsh".text = ''
    if [ -r "${config.sops.templates."user-runtime-secrets.env".path}" ]; then
      source "${config.sops.templates."user-runtime-secrets.env".path}"
    fi
  '';
}
