{ lib, config, pkgs, ... }:
let
  adoptedProfiles = {
    dubnium = ../../files/home/.config/hypr/adopted.d/dubnium.conf;
    technetium = ../../files/home/.config/hypr/adopted.d/technetium.conf;
    empty = ../../files/home/.config/hypr/adopted.d/empty.conf;
  };

  managedHyprConfig = builtins.readFile adoptedProfiles.${config.dotfiles.hypr.adoptedProfile};

  defaultWallpapers = pkgs.runCommand "dubnium-default-wallpapers" {
    nativeBuildInputs = [ pkgs.imagemagick ];
  } ''
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
    "dub-terminal"
    "dub-waybar-reload"
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

  localLayerText = tool: ''
    # Local ${tool} configuration layer.
    #
    # Ownership:
    # - machine-specific
    # - never automatically promoted
    #
    # Note: not every tool can source this file directly at runtime. For tools
    # without native include support, this file is still the configctl local
    # layer and should be manually folded into the managed config when promoted.
  '';
in
{
  options.dotfiles.hypr.adoptedProfile = lib.mkOption {
    type = lib.types.enum (builtins.attrNames adoptedProfiles);
    default = "empty";
    description = "Machine-specific Hyprland profile content to embed into the managed generated config.";
  };

  config = lib.mkIf config.dotfiles.profiles.workstation.enable {
    home.packages = [
      pkgs.variety
    ];

    xdg.configFile."hypr/hyprland.conf".text = ''
      # GENERATED FILE — DO NOT EDIT DIRECTLY
      # source-of-truth: ryjen/dotfiles
      # local-layer: ~/.config/hypr/local.conf
      # custom-layer: ~/.config/hypr/custom.d/*.conf
      # adopted-layer: ~/.config/hypr/adopted.d/*
      #
      # adopted.d is retained for adopted/archive fragments and is not sourced
      # during normal load.

      ${managedHyprConfig}

      source = ~/.config/hypr/local.conf
      source = ~/.config/hypr/custom.d/*.conf
    '';

    xdg.configFile."hypr/adopted.d/machine.conf".source = adoptedProfiles.${config.dotfiles.hypr.adoptedProfile};
    xdg.configFile."hypr/custom.d/00-empty.conf".source = ../../files/home/.config/hypr/custom.d/empty.conf;
    xdg.configFile."hypr/hyprpaper.conf".source = ../../files/home/.config/hypr/hyprpaper.conf;
    xdg.configFile."hyprpaper/local.conf".text = localLayerText "Hyprpaper";
    xdg.configFile."hyprpaper/custom.d/00-empty.conf".source = ../../files/home/.config/hyprpaper/custom.d/empty.conf;
    xdg.configFile."hyprpaper/adopted.d/00-empty.conf".source = ../../files/home/.config/hyprpaper/adopted.d/empty.conf;
    xdg.configFile."waybar/config.jsonc".source = ../../files/home/.config/waybar/config.jsonc;
    xdg.configFile."waybar/style.css".source = ../../files/home/.config/waybar/style.css;
    xdg.configFile."waybar/colors.css".source = ../../files/home/.config/waybar/colors.css;
    xdg.configFile."waybar/custom.css".source = ../../files/home/.config/waybar/custom.css;
    xdg.configFile."waybar/local.conf".text = localLayerText "Waybar";
    xdg.configFile."waybar/custom.d/00-empty.conf".source = ../../files/home/.config/waybar/custom.d/empty.conf;
    xdg.configFile."waybar/adopted.d/00-empty.conf".source = ../../files/home/.config/waybar/adopted.d/empty.conf;
    xdg.configFile."mako/config".source = ../../files/home/.config/mako/config;
    xdg.configFile."mako/local.conf".text = localLayerText "Mako";
    xdg.configFile."mako/custom.d/00-empty.conf".source = ../../files/home/.config/mako/custom.d/empty.conf;
    xdg.configFile."mako/adopted.d/00-empty.conf".source = ../../files/home/.config/mako/adopted.d/empty.conf;
    xdg.configFile."wofi/config".source = ../../files/home/.config/wofi/config;
    xdg.configFile."eww/eww.yuck".source = ../../files/home/.config/eww/eww.yuck;
    xdg.configFile."eww/eww.scss".source = ../../files/home/.config/eww/eww.scss;
    xdg.configFile."eww/local.conf".text = localLayerText "Eww";
    xdg.configFile."eww/custom.d/00-empty.conf".source = ../../files/home/.config/eww/custom.d/empty.conf;
    xdg.configFile."eww/adopted.d/00-empty.conf".source = ../../files/home/.config/eww/adopted.d/empty.conf;

    home.file = managedFiles;

    home.activation.configureVarietyWallpaperFolders = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      variety_config="$HOME/.config/variety/variety.conf"
      variety_downloads="$HOME/Pictures/wallpaper/variety/downloaded"
      variety_fetched="$HOME/Pictures/wallpaper/variety/fetched"
      variety_favorites="$HOME/Pictures/wallpaper/variety/favorites"

      mkdir -p "$HOME/.config/variety" \
        "$variety_downloads" \
        "$variety_fetched" \
        "$variety_favorites"

      touch "$variety_config"
      chmod 600 "$variety_config"

      tmp="$(${pkgs.coreutils}/bin/mktemp)"
      ${pkgs.gnugrep}/bin/grep -Ev '^(download_folder|fetched_folder|favorites_folder|copyto_folder|wallpaper_auto_rotate|change_enabled|change_on_start)\s*=' "$variety_config" > "$tmp" || true
      cat >> "$tmp" <<EOF
      download_folder = ~/Pictures/wallpaper/variety/downloaded
      fetched_folder = ~/Pictures/wallpaper/variety/fetched
      favorites_folder = ~/Pictures/wallpaper/variety/favorites
      copyto_folder = ~/Pictures/wallpaper/variety/favorites
      wallpaper_auto_rotate = False
      change_enabled = False
      change_on_start = False
      EOF
      cat "$tmp" > "$variety_config"
      rm -f "$tmp"
      chmod 600 "$variety_config"
    '';

    xdg.configFile."hypr/local.conf".text = ''
      # Local Hyprland configuration.
      #
      # Ownership:
      # - machine-specific
      # - writable by the user
      # - never automatically promoted
      #
      # Examples:
      # monitor=,preferred,auto,1
      # $terminal = alacritty
      # exec-once = alacritty
    '';
  };
}
