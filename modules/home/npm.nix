{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.npm;

  npmGlobalsSync = pkgs.writeShellApplication {
    name = "npm-globals-sync";
    runtimeInputs = with pkgs; [
      coreutils
      gnused
      nodejs
    ];
    text = ''
      set -euo pipefail

      usage() {
        printf '%s\n' \
          'Usage: npm-globals-sync [--dry-run]' \
          '' \
          'Install npm global packages declared by Home Manager.' \
          'Package entries are read from ~/.config/npm/global-packages.txt.' \
          'Blank lines and comments are ignored.'
      }

      dry_run=0
      case "''${1:-}" in
        --dry-run)
          dry_run=1
          shift
          ;;
        -h|--help)
          usage
          exit 0
          ;;
      esac

      if [ "$#" -ne 0 ]; then
        usage >&2
        exit 2
      fi

      if [ "$(id -u)" -eq 0 ]; then
        echo "refusing to run npm global sync as root" >&2
        exit 1
      fi

      if ! command -v npm >/dev/null 2>&1; then
        echo "npm is not available on PATH" >&2
        exit 1
      fi

      prefix="${cfg.prefix}"
      packages_file="$HOME/${cfg.globalPackagesFile}"

      mkdir -p "$prefix/bin"

      configured_prefix="$(npm config get prefix)"
      if [ "$configured_prefix" != "$prefix" ]; then
        echo "warning: npm prefix is $configured_prefix, expected $prefix" >&2
        echo "         Home Manager should manage ~/.npmrc; re-activate if this persists." >&2
      fi

      if [ ! -f "$packages_file" ]; then
        echo "missing npm global package list: $packages_file" >&2
        exit 1
      fi

      installed=0
      while IFS= read -r package || [ -n "$package" ]; do
        package="$(printf '%s\n' "$package" | sed -e 's/[[:space:]]*#.*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        [ -n "$package" ] || continue

        if [ "$dry_run" -eq 1 ]; then
          printf 'would install: %s\n' "$package"
        else
          printf 'installing npm global: %s\n' "$package"
          npm install -g "$package"
        fi
        installed=$((installed + 1))
      done < "$packages_file"

      if [ "$installed" -eq 0 ]; then
        echo "no npm global packages declared"
      fi
    '';
  };
in
{
  options.dotfiles.npm = {
    enable = lib.mkEnableOption "npm global tooling with a Home Manager user prefix";

    prefix = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/.local/share/npm";
      description = "User-writable npm global prefix.";
    };

    globalPackagesFile = lib.mkOption {
      type = lib.types.str;
      default = ".config/npm/global-packages.txt";
      description = "Home-relative package list consumed by npm-globals-sync.";
    };
  };

  config = lib.mkMerge [
    {
      dotfiles.npm.enable = lib.mkDefault config.dotfiles.profiles.workstation.enable;
    }

    (lib.mkIf cfg.enable {
      home.packages = [
        npmGlobalsSync
        pkgs.nodejs
      ];

      home.file.".npmrc".text = ''
        # Managed by Home Manager.
        # Keep machine-local auth tokens out of this repository-managed file.
        # Use npm login, environment variables, or a local untracked config for secrets.
        prefix=${cfg.prefix}
      '';

      home.file."${cfg.globalPackagesFile}".source = ../../files/home/.config/npm/global-packages.txt;

      home.sessionPath = [
        "${cfg.prefix}/bin"
      ];

      home.activation.npmGlobalPrefix = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${cfg.prefix}" "${cfg.prefix}/bin"
      '';
    })
  ];
}
