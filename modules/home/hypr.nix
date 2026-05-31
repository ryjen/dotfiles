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

      $terminal = alacritty

      bind = SUPER, RETURN, exec, $terminal

      source = ~/.config/hypr/local.conf
      source = ~/.config/hypr/custom.d/*.conf
    '';

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
