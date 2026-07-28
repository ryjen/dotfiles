{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.idle;
in
{
  options.dotfiles.idle.enable = lib.mkEnableOption "desktop idle locking and display power management";

  config = lib.mkIf (cfg.enable && config.dotfiles.profiles.workstation.enable) {
    home.packages = [
      pkgs.hypridle
      pkgs.hyprlock
    ];

    xdg.configFile."hypr/hypridle.conf".text = ''
      general {
          lock_cmd = pidof hyprlock || hyprlock
          before_sleep_cmd = loginctl lock-session
          after_sleep_cmd = hyprctl dispatch dpms on
      }

      listener {
          timeout = 600
          on-timeout = pidof hyprlock || hyprlock
      }

      listener {
          timeout = 900
          on-timeout = hyprctl dispatch dpms off
          on-resume = hyprctl dispatch dpms on
      }
    '';

    xdg.configFile."hypr/hyprlock.conf".text = ''
      general {
          disable_loading_bar = true
          hide_cursor = true
      }

      background {
          monitor =
          path = screenshot
          blur_passes = 3
          blur_size = 8
      }

      input-field {
          monitor =
          size = 320, 56
          position = 0, -40
          halign = center
          valign = center
          placeholder_text = <i>Password</i>
          fail_text = <i>Authentication failed</i>
      }

      label {
          monitor =
          text = cmd[update:1000] date +"%I:%M %p"
          font_size = 64
          position = 0, 100
          halign = center
          valign = center
      }
    '';

    systemd.user.services.dubnium-idle = lib.mkIf config.dotfiles.host.userSystemd.enable {
      Unit = {
        Description = "Dubnium desktop idle policy";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        Conflicts = [ "dubnium-meeting-mode.service" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.hypridle}/bin/hypridle -c %h/.config/hypr/hypridle.conf";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
