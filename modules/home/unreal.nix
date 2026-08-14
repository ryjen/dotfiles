{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.unreal;

  unrealInstaller = pkgs.writeShellApplication {
    name = "unreal-install";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.unzip
    ];
    text = ''
      if [[ $# -ne 1 ]]; then
        echo "usage: unreal-install /path/to/Linux_Unreal_Engine.zip" >&2
        exit 64
      fi

      archive="$(realpath -e -- "$1")"
      engine_root=${lib.escapeShellArg cfg.engineRoot}
      parent="$(dirname -- "$engine_root")"

      if [[ ! -f "$archive" ]]; then
        echo "Unreal Engine archive is not a regular file: $archive" >&2
        exit 66
      fi

      if [[ -e "$engine_root" ]]; then
        echo "Unreal Engine install already exists: $engine_root" >&2
        echo "Choose a different dotfiles.unreal.engineRoot for another version." >&2
        exit 73
      fi

      unzip -tq -- "$archive" >/dev/null

      while IFS= read -r entry; do
        case "$entry" in
          /*|../*|*/../*|*/..)
            echo "Refusing archive with unsafe path: $entry" >&2
            exit 65
            ;;
        esac
      done < <(unzip -Z1 -- "$archive")

      mkdir -p -- "$parent"
      staging="$(mktemp -d "$parent/.unreal-engine.XXXXXX")"
      cleanup() {
        rm -rf -- "$staging"
      }
      trap cleanup EXIT

      unzip -q -- "$archive" -d "$staging"

      editor="$staging/Engine/Binaries/Linux/UnrealEditor"
      if [[ ! -f "$editor" ]]; then
        echo "Archive does not contain Engine/Binaries/Linux/UnrealEditor at its root." >&2
        echo "Expected an Epic Linux installed-build archive." >&2
        exit 65
      fi

      chmod +x -- "$editor"
      mv -- "$staging" "$engine_root"
      trap - EXIT

      echo "Installed Unreal Engine at $engine_root"
      echo "Launch it with: unreal-editor"
    '';
  };

  unrealEditor = pkgs.writeShellApplication {
    name = "unreal-editor";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.steam.run-free
    ];
    text = ''
      engine_root=${lib.escapeShellArg cfg.engineRoot}
      cache_root=${lib.escapeShellArg cfg.cacheRoot}
      editor="$engine_root/Engine/Binaries/Linux/UnrealEditor"
      zen_data="$cache_root/zen"

      if [[ ! -x "$editor" ]]; then
        echo "Unreal Editor is not installed at: $editor" >&2
        echo "Download an Unreal Engine Linux installed-build ZIP from Epic, then run:" >&2
        echo "  unreal-install /path/to/Linux_Unreal_Engine.zip" >&2
        exit 127
      fi

      mkdir -p -- "$zen_data"
      export UE_ROOT="$engine_root"

      # Epic's Installed Build model supports a read-only engine distribution.
      # Keep Zen/DDC mutation in an explicit user-writable cache location rather
      # than relying on engine-relative cache state.
      exec env "UE-ZenDataPath=$zen_data" steam-run "$editor" "$@"
    '';
  };
in
{
  options.dotfiles.unreal = {
    enable = lib.mkEnableOption "Unreal Editor support";

    engineRoot = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.dataHome}/unreal-engine";
      example = "/data/unreal/5.8";
      description = "Directory containing the extracted Unreal Engine Linux installed build";
    };

    cacheRoot = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.cacheHome}/unreal-engine";
      example = "/data/cache/unreal-engine";
      description = "Writable cache root used for Unreal Zen/DDC state";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.hasPrefix "/" cfg.engineRoot;
        message = "dotfiles.unreal.engineRoot must be an absolute path";
      }
      {
        assertion =
          cfg.engineRoot != "/"
          && cfg.engineRoot != "/nix/store"
          && !lib.hasPrefix "/nix/store/" cfg.engineRoot;
        message = "dotfiles.unreal.engineRoot must live outside / and /nix/store";
      }
      {
        assertion = lib.hasPrefix "/" cfg.cacheRoot;
        message = "dotfiles.unreal.cacheRoot must be an absolute path";
      }
      {
        assertion =
          cfg.cacheRoot != "/"
          && cfg.cacheRoot != "/nix/store"
          && !lib.hasPrefix "/nix/store/" cfg.cacheRoot;
        message = "dotfiles.unreal.cacheRoot must be writable storage outside / and /nix/store";
      }
    ];

    home.packages = [
      unrealEditor
      unrealInstaller
    ];

    home.sessionVariables.UE_ROOT = cfg.engineRoot;

    xdg.desktopEntries.unreal-editor = {
      name = "Unreal Editor";
      genericName = "Game engine editor";
      comment = "Create and edit Unreal Engine projects";
      exec = "unreal-editor %F";
      icon = "applications-development";
      terminal = false;
      startupNotify = true;
      categories = [
        "Development"
        "Graphics"
        "3DGraphics"
      ];
    };
  };
}
