{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.meeting;
  obsHotkeyHelper = lib.escapeShellArg "${config.home.homeDirectory}/.local/bin/dub-obs-hotkey";
  ewwOverlayHelper = lib.escapeShellArg "${config.home.homeDirectory}/.local/libexec/dubnium-eww-quote-overlay";
  singleLineString = lib.types.strMatching "[^\n\r]*";
  drmConnector = lib.types.strMatching "[A-Za-z][A-Za-z0-9]*(-[A-Za-z0-9]+)+";
in
{
  options.dotfiles.meeting = {
    enable = lib.mkEnableOption "meeting and presentation workspace support";
    zoom.enable = lib.mkEnableOption "the Zoom desktop client";
    teams.enable = lib.mkEnableOption "Teams-specific meeting integration";

    presentationOutput = lib.mkOption {
      type = lib.types.nullOr drmConnector;
      default = null;
      description = "Optional DRM connector name for the presentation workspace.";
    };

    cameraDevice = lib.mkOption {
      type = lib.types.nullOr singleLineString;
      default = null;
      description = "Optional machine-local OBS camera device identifier.";
    };

    phoneCamera.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install USB-only Android phone camera bridge tooling for meeting sessions.";
    };

    teamsClassRegex = lib.mkOption {
      type = singleLineString;
      default = "^(firefox|Microsoft-edge|microsoft-edge)$";
      description = "Hyprland class regex for Teams browser or PWA windows.";
    };

    teamsTitleRegex = lib.mkOption {
      type = singleLineString;
      default = "^Microsoft Teams.*$";
      description = "Hyprland title regex for Teams browser or PWA windows.";
    };
  };

  config = lib.mkMerge [
    {
      # Application and camera tooling are independent of meeting workspace UX.
      home.packages =
        lib.optionals cfg.zoom.enable [ pkgs.zoom-us ]
        ++ lib.optionals cfg.phoneCamera.enable [
          pkgs.android-tools
          pkgs.scrcpy
          pkgs.v4l-utils
        ];

      home.file.".local/bin/dubctl-phone-camera" = lib.mkIf cfg.phoneCamera.enable {
        source = ../../files/home/.local/bin/dubctl-phone-camera;
        executable = true;
      };
    }
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = config.dotfiles.host.graphical.enable;
          message = "dotfiles.meeting.enable requires dotfiles.host.graphical.enable.";
        }
        {
          assertion = config.dotfiles.host.userSystemd.enable;
          message = "dotfiles.meeting.enable requires Home Manager user systemd support.";
        }
      ];

      xdg = {
        configFile = {
          "hypr/custom.d/meeting.conf".text = ''
            ${lib.optionalString (
              cfg.presentationOutput != null
            ) "workspace = name:presentation, monitor:${cfg.presentationOutput}"}

            bind = SUPER, G, togglespecialworkspace, meeting
            bind = SUPER SHIFT, G, movetoworkspace, special:meeting
            bind = SUPER, P, workspace, name:presentation
            bind = SUPER SHIFT, P, movetoworkspace, name:presentation
            bind = SUPER CTRL, 1, exec, ${obsHotkeyHelper} code-only
            bind = SUPER CTRL, 2, exec, ${obsHotkeyHelper} code-camera
            bind = SUPER CTRL, 3, exec, ${obsHotkeyHelper} camera-toggle

            ${lib.optionalString cfg.zoom.enable ''
              windowrule {
                  name = meeting-zoom-controls
                  match:class = ^(zoom|Zoom)$
                  workspace = special:meeting
              }
            ''}

            ${lib.optionalString cfg.teams.enable ''
              windowrule {
                  name = meeting-teams-controls
                  match:class = ${cfg.teamsClassRegex}
                  match:title = ${cfg.teamsTitleRegex}
                  workspace = special:meeting
              }
            ''}

            windowrule {
                name = meeting-obs-controls
                match:class = ^(obs|com.obsproject.Studio)$
                workspace = special:meeting
            }

            windowrule {
                name = meeting-obs-projector
                match:class = ^(obs|com.obsproject.Studio)$
                match:title = ^Fullscreen Projector.*$
                workspace = name:presentation
                fullscreen = on
            }
          '';

          "dubnium/meeting/obs-init.json".text = builtins.toJSON {
            inherit (cfg) cameraDevice;
          };

        };

        dataFile."dubnium/obs/v1" = {
          source = ../../files/home/.local/share/dubnium/obs/v1;
          recursive = true;
        };
      };

      home = {
        file = {
          ".local/bin/dub-obs-hotkey" = {
            source = ../../files/home/.local/bin/dub-obs-hotkey;
            executable = true;
          };
          ".local/bin/dub-meeting-session" = {
            source = ../../files/home/.local/bin/dub-meeting-session;
            executable = true;
          };
          ".local/libexec/dubnium-meeting-mode" = {
            source = ../../files/home/.local/libexec/dubnium-meeting-mode;
            executable = true;
          };
          ".local/libexec/dubnium-eww-quote-overlay" = {
            source = ../../files/home/.local/libexec/dubnium-eww-quote-overlay;
            executable = true;
          };
          ".local/bin/dub-eww-quote-overlay" = {
            executable = true;
            text = ''
              #!/usr/bin/env bash
              export DUBNIUM_PRESENTATION_OUTPUT=${
                lib.escapeShellArg (if cfg.presentationOutput == null then "" else cfg.presentationOutput)
              }
              exec ${ewwOverlayHelper} "$@"
            '';
          };
        };
      };

      systemd.user.services.dubnium-meeting-mode = lib.mkIf config.dotfiles.host.userSystemd.enable {
        Unit = {
          Description = "Dubnium meeting privacy mode";
          Conflicts = [ "dubnium-idle.service" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          Environment = "DUBNIUM_PRESENTATION_OUTPUT=${
            lib.optionalString (cfg.presentationOutput != null) cfg.presentationOutput
          }";
          ExecStart = "%h/.local/libexec/dubnium-meeting-mode start";
          ExecStop = "%h/.local/libexec/dubnium-meeting-mode stop";
          ExecStopPost = "-${pkgs.systemd}/bin/systemctl --user --no-block start dubnium-idle.service";
        };
      };

      systemd.user.services.dubnium-cliphist = lib.mkIf config.dotfiles.host.userSystemd.enable {
        Unit.Description = "Dubnium clipboard history watcher";
        Service = {
          Type = "simple";
          ExecCondition = "%h/.local/libexec/dubnium-meeting-mode can-capture";
          ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    })
  ];
}
