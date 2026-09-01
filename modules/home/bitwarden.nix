{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.bitwarden;
in
{
  options.dotfiles.bitwarden = {
    cli.enable = lib.mkEnableOption "Bitwarden command-line client";
    desktop.enable = lib.mkEnableOption "Bitwarden desktop client";

    serverUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "https://warden.tail4d84c.ts.net";
      description = ''
        Optional self-hosted Vaultwarden/Bitwarden server origin for the CLI and
        desktop clients.

        When set, the CLI's configured server is materialized declaratively so
        `bw` targets the self-hosted origin instead of the Bitwarden cloud. The
        browser extension cannot be configured this way and must still have its
        server URL set manually; see docs/bitwarden.md.

        This must be an origin including the scheme. No credentials or
        `BW_SESSION` value is ever written by this module.
      '';
    };
  };

  config = lib.mkMerge [
    {
      home.packages =
        lib.optionals cfg.cli.enable [ pkgs.bitwarden-cli ]
        ++ lib.optionals cfg.desktop.enable [ pkgs.bitwarden-desktop ];
    }

    (lib.mkIf (cfg.serverUrl != null) {
      assertions = [
        {
          assertion = lib.hasPrefix "https://" cfg.serverUrl || lib.hasPrefix "http://" cfg.serverUrl;
          message = "dotfiles.bitwarden.serverUrl must include an http:// or https:// scheme.";
        }
      ];

      # `bw config server` writes into the CLI's own data directory, which is
      # mutable runtime state. Expose the intended origin through the
      # environment instead so the value stays declarative and no secret or
      # session token is placed in the Nix store.
      home.sessionVariables.BITWARDENCLI_SERVER = cfg.serverUrl;
    })
  ];
}
