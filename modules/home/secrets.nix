{ config, ... }:
{
  sops = {
    defaultSopsFile = ../../secrets.yaml;
    gnupg.home = "${config.home.homeDirectory}/.gnupg";

    # Define which secrets to decrypt
    secrets = {
      github_token = { };
      openai_api_key = { };
      anthropic_api_key = { };
    };
  };

  # Example of injecting secrets into the environment
  home.sessionVariables = {
    # This points to the decrypted file in a secure location (usually /run/user/1000/secrets)
    GITHUB_TOKEN_PATH = config.sops.secrets.github_token.path;
  };
}
