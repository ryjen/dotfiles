{
  lib,
  config,
  pkgs,
  ...
}:
let
  adoptedProfiles = {
    dubnium = ../../files/home/.config/hypr/adopted.d/dubnium.conf;
    technetium = ../../files/home/.config/hypr/adopted.d/technetium.conf;
    empty = ../../files/home/.config/hypr/adopted.d/empty.conf;
  };

  machineProfile = config.dotfiles.host.name;
  machineProfileName = if machineProfile == null then "unconfigured" else machineProfile;
  hyprPromotedProfilesRoot = ../../files/home/.config/hypr/custom.d;
  hyprPromotedProfile = hyprPromotedProfilesRoot + "/${machineProfileName}";
  hasHyprPromotedProfile = machineProfile != null && builtins.pathExists hyprPromotedProfile;

  managedHyprConfig = builtins.readFile adoptedProfiles.${config.dotfiles.hypr.adoptedProfile};

  defaultWallpapers =
    pkgs.runCommand "dubnium-default-wallpapers"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
      }
      ''
        mkdir -p "$out"

        magick -size 2560x1440 gradient:"#020617-#0f766e" \
          "$out/dubnium-teal.png"

        magick -size 2560x1440 gradient:"#111827-#6d28d9" \
          "$out/dubnium-violet.png"

        magick -size 2560x1440 gradient:"#0f172a-#b45309" \
          "$out/dubnium-amber.png"
      '';

  managedScripts = [
    "dub-browser"
    "dub-clipboard"
    "dub-editor"
    "dub-file-manager"
    "dub-launch"
    "dub-screenshot"
    "dub-session-doctor"
    "dub-session-reset"
    "dub-session-start"
    "dub-terminal"
    "dub-waybar-reload"
    "music-status"
    "music-toggle"
    "random-wallpaper"
    "random-quote"
  ];

  managedScriptFile = name: {
    name = ".local/bin/${name}";
    value = {
      source = ../../files/home/.local/bin/${name};
      executable = true;
    };
  };

  managedFiles = builtins.listToAttrs (map managedScriptFile managedScripts) // {
    "Pictures/wallpaper/defaults" = {
      source = defaultWallpapers;
      recursive = true;
    };
  };
in
{
  options.dotfiles.hypr.adoptedProfile = lib.mkOption {
    type = lib.types.enum (builtins.attrNames adoptedProfiles);
    default = "empty";
    description = "Machine-specific Hyprland profile content to embed into the managed generated config.";
  };

  config = lib.mkIf config.dotfiles.profiles.workstation.enable {
    home.packages = [
      pkgs.lm_sensors
      pkgs.playerctl
      pkgs.python3
      pkgs.variety
    ];

    xdg.configFile."hypr/hyprland.conf".text = ''
      # GENERATED FILE — DO NOT EDIT DIRECTLY
      # source-of-truth: ryjen/dotfiles
      # promoted-layer: ~/.config/hypr/custom.d/<machine-profile>/*.conf
      # custom-layer: ~/.config/hypr/custom.d/*.conf
      # local-layer: ~/.config/hypr/local.conf
      # adopted-layer: ~/.config/hypr/adopted.d/*
      #
      # adopted.d is retained for adopted/archive fragments and is not sourced
      # during normal load.

      ${managedHyprConfig}

      ${lib.optionalString hasHyprPromotedProfile "source = ~/.config/hypr/custom.d/${machineProfileName}/*.conf"}
      source = ~/.config/hypr/custom.d/*.conf
      source = ${config.home.homeDirectory}/.config/hypr/local.conf
    '';

    xdg.configFile."hypr/adopted.d/machine.conf".source =
      adoptedProfiles.${config.dotfiles.hypr.adoptedProfile};
    xdg.configFile."hypr/custom.d/00-empty.conf".source =
      ../../files/home/.config/hypr/custom.d/empty.conf;
    xdg.configFile."hypr/custom.d/10-cursor.conf".source =
      ../../files/home/.config/hypr/custom.d/cursor.conf;
    xdg.configFile."hypr/hyprpaper.conf".source = ../../files/home/.config/hypr/hyprpaper.conf;
    xdg.configFile."hyprpaper/custom.d/00-empty.conf".source =
      ../../files/home/.config/hyprpaper/custom.d/empty.conf;
    xdg.configFile."hyprpaper/adopted.d/00-empty.conf".source =
      ../../files/home/.config/hyprpaper/adopted.d/empty.conf;

    xdg.configFile."mako/config".source = ../../files/home/.config/mako/config;
    xdg.configFile."mako/custom.d/00-empty.conf".source =
      ../../files/home/.config/mako/custom.d/empty.conf;
    xdg.configFile."mako/adopted.d/00-empty.conf".source =
      ../../files/home/.config/mako/adopted.d/empty.conf;
    xdg.configFile."wofi/config".source = ../../files/home/.config/wofi/config;
    xdg.configFile."eww/eww.yuck".source = ../../files/home/.config/eww/eww.yuck;
    xdg.configFile."eww/eww.scss".source = ../../files/home/.config/eww/eww.scss;
    xdg.configFile."eww/custom.d/00-empty.conf".source =
      ../../files/home/.config/eww/custom.d/empty.conf;
    xdg.configFile."eww/adopted.d/00-empty.conf".source =
      ../../files/home/.config/eww/adopted.d/empty.conf;

    xdg.configFile = lib.mkIf hasHyprPromotedProfile {
      "hypr/custom.d/${machineProfileName}" = {
        source = hyprPromotedProfile;
        recursive = true;
      };
    };

    home.file = managedFiles;

    home.activation.ensureHyprLocalConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      local_config="$HOME/.config/hypr/local.conf"
      if [ ! -e "$local_config" ]; then
        ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$local_config")"
        ${pkgs.coreutils}/bin/printf '%s\n' '# Place host-local or user overrides here.' > "$local_config"
      fi
    '';

    home.activation.configureVarietyWallpaperFolders = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      variety_config="$HOME/.config/variety/variety.conf"
      variety_downloads="$HOME/Pictures/wallpaper/variety/downloaded"
      variety_fetched="$HOME/Pictures/wallpaper/variety/fetched"
      variety_favorites="$HOME/Pictures/wallpaper/variety/favorites"

      mkdir -p "$HOME/.config/variety" \
        "$variety_downloads" \
        "$variety_fetched" \
        "$variety_favorites"

      (
        tmp="$(${pkgs.coreutils}/bin/mktemp)"
        trap '${pkgs.coreutils}/bin/rm -f "$tmp"' EXIT

        if [ -f "$variety_config" ]; then
          grep_status=0
          ${pkgs.gnugrep}/bin/grep -Ev '^(download_folder|fetched_folder|favorites_folder|copyto_folder|wallpaper_auto_rotate|change_enabled|change_on_start)[[:space:]]*=' "$variety_config" > "$tmp" || grep_status=$?
          if [ "$grep_status" -gt 1 ]; then
            exit "$grep_status"
          fi
        fi
        {
          printf '%s\n' 'download_folder = ~/Pictures/wallpaper/variety/downloaded'
          printf '%s\n' 'fetched_folder = ~/Pictures/wallpaper/variety/fetched'
          printf '%s\n' 'favorites_folder = ~/Pictures/wallpaper/variety/favorites'
          printf '%s\n' 'copyto_folder = ~/Pictures/wallpaper/variety/favorites'
          printf '%s\n' 'wallpaper_auto_rotate = False'
          printf '%s\n' 'change_enabled = False'
          printf '%s\n' 'change_on_start = False'
        } >> "$tmp"

        if [ ! -f "$variety_config" ] || ! ${pkgs.diffutils}/bin/cmp -s "$tmp" "$variety_config"; then
          ${pkgs.coreutils}/bin/install -m 0600 "$tmp" "$variety_config"
        elif [ "$(${pkgs.coreutils}/bin/stat -c %a "$variety_config")" != "600" ]; then
          ${pkgs.coreutils}/bin/chmod 600 "$variety_config"
        fi
      )
    '';
  };
}
