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

      if [[ -e "$engine_root" ]]; then
        echo "Unreal Engine install already exists: $engine_root" >&2
        echo "Choose a different dotfiles.unreal.engineRoot for another version." >&2
        exit 73
      fi

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
      pkgs.steam-run
    ];
    text = ''
      engine_root=${lib.escapeShellArg cfg.engineRoot}
      editor="$engine_root/Engine/Binaries/Linux/UnrealEditor"

      if [[ ! -x "$editor" ]]; then
        echo "Unreal Editor is not installed at: $editor" >&2
        echo "Download an Unreal Engine Linux installed-build ZIP from Epic, then run:" >&2
        echo "  unreal-install /path/to/Linux_Unreal_Engine.zip" >&2
        exit 127
      fi

      export UE_ROOT="$engine_root"
      exec steam-run "$editor" "$@"
    '';
  };
in
{
  options.dotfiles.unreal = {
    enable = lib.mkEnableOption "Unreal Editor support";

    engineRoot = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.dataHome}/unreal-engine";
      example = "/mnt/isotope/Unreal/5.8";
      description = "Mutable directory containing the extracted Unreal Engine Linux installed build";
    };
  };

  config = lib.mkIf cfg.enable {
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
