{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.openwork;

  openworkUpdate = pkgs.writeShellApplication {
    name = "openwork-update";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.jq
    ];
    text = ''
      set -euo pipefail

      readonly api_url="https://api.github.com/repos/different-ai/openwork/releases/latest"
      readonly data_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/openwork"
      readonly releases_dir="$data_dir/releases"
      readonly current_app="$data_dir/OpenWork.AppImage"

      temp_dir="$(mktemp -d)"
      trap 'rm -rf "$temp_dir"' EXIT

      metadata_file="$temp_dir/release.json"
      curl \
        --proto '=https' \
        --tlsv1.2 \
        --fail \
        --location \
        --silent \
        --show-error \
        --header 'Accept: application/vnd.github+json' \
        --output "$metadata_file" \
        "$api_url"

      version="$(jq -er '.tag_name | ltrimstr("v")' "$metadata_file")"
      asset_name="openwork-linux-x86_64-$version.AppImage"
      asset_json="$(
        jq -cer --arg asset_name "$asset_name" \
          '.assets[] | select(.name == $asset_name)' \
          "$metadata_file"
      )"
      asset_url="$(jq -er '.browser_download_url' <<<"$asset_json")"
      digest="$(
        jq -er \
          '.digest | select(type == "string" and startswith("sha256:"))' \
          <<<"$asset_json"
      )"

      case "$asset_url" in
        https://github.com/different-ai/openwork/releases/download/*) ;;
        *)
          echo "Refusing unexpected OpenWork asset URL: $asset_url" >&2
          exit 1
          ;;
      esac

      target_dir="$releases_dir/$version"
      target_app="$target_dir/$asset_name"
      expected_sha="''${digest#sha256:}"

      mkdir -p "$target_dir"

      if [[ -f "$target_app" ]]; then
        actual_sha="$(sha256sum "$target_app" | cut -d' ' -f1)"
        if [[ "$actual_sha" != "$expected_sha" ]]; then
          echo "Removing OpenWork asset with an invalid digest: $target_app" >&2
          rm -f "$target_app"
        fi
      fi

      if [[ ! -f "$target_app" ]]; then
        temporary_app="$temp_dir/$asset_name"
        curl \
          --proto '=https' \
          --tlsv1.2 \
          --fail \
          --location \
          --silent \
          --show-error \
          --output "$temporary_app" \
          "$asset_url"

        actual_sha="$(sha256sum "$temporary_app" | cut -d' ' -f1)"
        if [[ "$actual_sha" != "$expected_sha" ]]; then
          echo "OpenWork AppImage digest verification failed" >&2
          exit 1
        fi

        install -m 0755 "$temporary_app" "$target_app"
      fi

      ln -sfn "$target_app" "$current_app"
      echo "OpenWork $version installed at $target_app"
    '';
  };

  openwork = pkgs.writeShellApplication {
    name = "openwork";
    runtimeInputs = [
      pkgs.appimage-run
      openworkUpdate
    ];
    text = ''
      set -euo pipefail

      readonly app="''${XDG_DATA_HOME:-$HOME/.local/share}/openwork/OpenWork.AppImage"
      if [[ ! -x "$app" ]]; then
        openwork-update
      fi

      exec appimage-run "$app" "$@"
    '';
  };
in
{
  options.dotfiles.openwork.enable = lib.mkEnableOption "OpenWork desktop AppImage launcher";

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.appimage-run
      openwork
      openworkUpdate
    ];

    xdg.desktopEntries.openwork = {
      name = "OpenWork";
      genericName = "AI workflow desktop";
      comment = "Run and share AI workflows";
      exec = "openwork %U";
      icon = "applications-development";
      terminal = false;
      startupNotify = true;
      categories = [
        "Development"
        "Utility"
      ];
      mimeType = [ "x-scheme-handler/openwork" ];
      settings.StartupWMClass = "OpenWork";
    };
  };
}
