{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.gpg;
  defaultKeyFile = if cfg.defaultKeyFile == null then "" else cfg.defaultKeyFile;
in
{
  options.dotfiles.gpg.defaultKeyFile = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Optional runtime file containing the default GPG key fingerprint.";
  };

  config = {
    home.packages = [
      pkgs.gnupg
    ];

    home.activation.ensureGnuPGHome = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -m 700 -p "$HOME/.gnupg"
      chmod 700 "$HOME/.gnupg"
    '';

    home.activation.writeGnuPGConfig = lib.hm.dag.entryAfter [ "ensureGnuPGHome" ] ''
      key=""
      if [ -n "${defaultKeyFile}" ] && [ -r "${defaultKeyFile}" ]; then
        key="$(${pkgs.coreutils}/bin/tr -d '\r\n' < "${defaultKeyFile}")"
      fi

      {
        echo "use-agent"
        if [ -n "$key" ]; then
          printf 'default-key %s\n' "$key"
          printf 'trusted-key %s\n' "$key"
        fi
      } > "$HOME/.gnupg/gpg.conf"
      chmod 600 "$HOME/.gnupg/gpg.conf"
    '';

    services.gpg-agent = {
      enable = true;
      pinentry.package = pkgs.pinentry-gtk2;
      enableZshIntegration = true;
      defaultCacheTtl = 1800;
      maxCacheTtl = 7200;
    };
  };
}
