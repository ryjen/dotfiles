{ lib, config, ... }:
let
  adoptedProfiles = {
    dubnium = ../../files/home/.config/hypr/adopted.d/dubnium.conf;
    technetium = ../../files/home/.config/hypr/adopted.d/technetium.conf;
    empty = ../../files/home/.config/hypr/adopted.d/empty.conf;
  };

  managedHyprConfig = builtins.readFile adoptedProfiles.${config.dotfiles.hypr.adoptedProfile};

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
in
{
  options.dotfiles.hypr.adoptedProfile = lib.mkOption {
    type = lib.types.enum (builtins.attrNames adoptedProfiles);
    default = "empty";
    description = "Machine-specific Hyprland profile content to embed into the managed generated config.";
  };

  config = lib.mkIf config.dotfiles.profiles.workstation.enable {
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
    xdg.configFile."waybar/config.jsonc".source = ../../files/home/.config/waybar/config.jsonc;
    xdg.configFile."waybar/style.css".source = ../../files/home/.config/waybar/style.css;
    xdg.configFile."waybar/colors.css".source = ../../files/home/.config/waybar/colors.css;
    xdg.configFile."waybar/custom.css".source = ../../files/home/.config/waybar/custom.css;
    xdg.configFile."mako/config".source = ../../files/home/.config/mako/config;
    xdg.configFile."wofi/config".source = ../../files/home/.config/wofi/config;
    xdg.configFile."eww/eww.yuck".source = ../../files/home/.config/eww/eww.yuck;
    xdg.configFile."eww/eww.scss".source = ../../files/home/.config/eww/eww.scss;

    home.file = builtins.listToAttrs (map managedScriptFile managedScripts);

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
