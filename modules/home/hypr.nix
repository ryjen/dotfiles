{ lib, config, ... }:
{
  config = lib.mkIf config.dotfiles.profiles.workstation.enable {
    xdg.configFile."hypr/hyprland.conf".text = ''
      # GENERATED FILE — DO NOT EDIT DIRECTLY
      # Source of truth: ryjen/dotfiles Home Manager modules
      #
      # Local machine-specific overrides:
      #   ~/.config/hypr/local.conf
      #
      # Promotion candidates:
      #   ~/.config/hypr/custom.d/*.conf
      #
      # Adopted fragments:
      #   ~/.config/hypr/adopted.d/*.conf
      #
      # configctl should never auto-promote local.conf.
      # configctl may reconcile and promote custom.d fragments.
      source = ~/.config/hypr/adopted.d/*.conf
      source = ~/.config/hypr/local.conf
      source = ~/.config/hypr/custom.d/*.conf
    '';

    xdg.configFile."hypr/adopted.d/technetium.conf".source = ../../files/home/.config/hypr/adopted.d/technetium.conf;
    xdg.configFile."hypr/hyprpaper.conf".source = ../../files/home/.config/hypr/hyprpaper.conf;
    xdg.configFile."waybar/config.jsonc".source = ../../files/home/.config/waybar/config.jsonc;
    xdg.configFile."waybar/style.css".source = ../../files/home/.config/waybar/style.css;
    xdg.configFile."waybar/colors.css".source = ../../files/home/.config/waybar/colors.css;
    xdg.configFile."mako/config".source = ../../files/home/.config/mako/config;
    xdg.configFile."wofi/config".source = ../../files/home/.config/wofi/config;
    xdg.configFile."eww/eww.yuck".source = ../../files/home/.config/eww/eww.yuck;
    xdg.configFile."eww/eww.scss".source = ../../files/home/.config/eww/eww.scss;

    home.file.".local/bin/random-wallpaper" = {
      source = ../../files/home/.local/bin/random-wallpaper;
      executable = true;
    };

    home.file.".local/bin/random-quote" = {
      source = ../../files/home/.local/bin/random-quote;
      executable = true;
    };

    xdg.configFile."hypr/local.conf".text = ''
      # Local Hyprland configuration.
      #
      # Ownership:
      # - machine-specific
      # - writable by the user
      # - never automatically promoted by configctl
      #
      # Examples:
      # monitor=,preferred,auto,1
      # $terminal = alacritty
      # exec-once = alacritty
    '';
  };
}
