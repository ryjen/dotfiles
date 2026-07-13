{
  lib,
  pkgs,
  config,
  ...
}:
{
  options.dotfiles.profiles.android.enable = lib.mkEnableOption "Android tooling overlay";

  config = lib.mkIf config.dotfiles.profiles.android.enable {
    home.packages = with pkgs; [
      android-studio
      android-tools
    ];

    home.activation.installAndroidAgentCli = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      target="$HOME/.local/bin/android"

      if [ ! -x "$target" ]; then
        mkdir -p "$(dirname "$target")"
        tmp="$(${pkgs.coreutils}/bin/mktemp)"
        trap '${pkgs.coreutils}/bin/rm -f "$tmp"' EXIT

        if ${pkgs.curl}/bin/curl \
          --fail \
          --silent \
          --show-error \
          --location \
          --connect-timeout 15 \
          --max-time 120 \
          https://dl.google.com/android/cli/latest/linux_x86_64/android \
          --output "$tmp"; then
          ${pkgs.coreutils}/bin/install -m 0755 "$tmp" "$target"
        else
          echo "warning: Android CLI download unavailable; install it from https://developer.android.com/tools/agents" >&2
        fi
      fi
    '';

    xdg.configFile."zsh/config.d/android".source = ../../files/home/.config/zsh/config.d/android;

    home.file.".local/bin/droidctl" = {
      source = ../../files/home/.local/bin/droidctl;
      executable = true;
    };
  };
}
