{
  config,
  lib,
  pkgs,
  ...
}:
let
  mkScopedSecretWrapper =
    {
      name,
      environmentVariable,
      secretPath,
    }:
    pkgs.writeShellApplication {
      inherit name;
      text = ''
        if [ "$#" -eq 0 ]; then
          echo "usage: ${name} <command> [args...]" >&2
          exit 64
        fi

        secret_path=${lib.escapeShellArg secretPath}
        if [ ! -f "$secret_path" ] || [ ! -r "$secret_path" ]; then
          echo "${name}: secret file is unavailable: $secret_path" >&2
          exit 66
        fi

        secret_value="$(<"$secret_path")"
        export ${environmentVariable}="$secret_value"
        unset secret_value secret_path
        exec "$@"
      '';
    };
in
{
  sops = {
    defaultSopsFile = ../../secrets.yaml;
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    gnupg.home = "${config.home.homeDirectory}/.gnupg";

    secrets = {
      github_token.mode = "0400";
      openai_api_key.mode = "0400";
      anthropic_api_key.mode = "0400";
    };
  };

  home.sessionVariables = {
    GITHUB_TOKEN_PATH = config.sops.secrets.github_token.path;
    OPENAI_API_KEY_PATH = config.sops.secrets.openai_api_key.path;
    ANTHROPIC_API_KEY_PATH = config.sops.secrets.anthropic_api_key.path;
  };

  home.packages = [
    (mkScopedSecretWrapper {
      name = "with-github-token";
      environmentVariable = "GITHUB_TOKEN";
      secretPath = config.sops.secrets.github_token.path;
    })
    (mkScopedSecretWrapper {
      name = "with-openai-key";
      environmentVariable = "OPENAI_API_KEY";
      secretPath = config.sops.secrets.openai_api_key.path;
    })
    (mkScopedSecretWrapper {
      name = "with-anthropic-key";
      environmentVariable = "ANTHROPIC_API_KEY";
      secretPath = config.sops.secrets.anthropic_api_key.path;
    })
  ];
}
