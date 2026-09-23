{ pkgs, home-manager }:
let
  lib = pkgs.lib;
  evalMeeting =
    {
      meeting ? false,
      zoom ? false,
      teams ? false,
      phone ? false,
    }:
    (home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ../modules/home/meeting.nix
        ({ lib, ... }: {
          options.dotfiles.host.graphical.enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
          options.dotfiles.host.userSystemd.enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
          config = {
            home.username = "camera-test";
            home.homeDirectory = "/home/camera-test";
            home.stateVersion = "25.05";
            dotfiles.meeting.enable = meeting;
            dotfiles.meeting.zoom.enable = zoom;
            dotfiles.meeting.teams.enable = teams;
            dotfiles.meeting.phoneCamera.enable = phone;
          };
        })
      ];
    }).config;
  none = evalMeeting { };
  zoomOnly = evalMeeting { zoom = true; };
  phoneOnly = evalMeeting { phone = true; };
  uxOnly = evalMeeting { meeting = true; };
  all = evalMeeting {
    meeting = true;
    zoom = true;
    teams = true;
    phone = true;
  };
  hasPkg = cfg: pkg: builtins.elem (toString pkg) (map toString cfg.home.packages);
  hasPhone = cfg: cfg.home.file ? ".local/bin/dubctl-phone-camera";
  hasUx = cfg: cfg.xdg.configFile ? "hypr/custom.d/meeting.conf";
  check = condition: message: if condition then "" else builtins.throw message;
  evaluated = builtins.concatStringsSep "" [
    (check (!hasPkg none pkgs.zoom-us && !hasPhone none && !hasUx none)
      "disabled meeting must install neither optional apps nor meeting UX")
    (check (hasPkg zoomOnly pkgs.zoom-us && !hasPhone zoomOnly && !hasUx zoomOnly)
      "Zoom must install when meeting UX is disabled")
    (check (!hasPkg phoneOnly pkgs.zoom-us && hasPhone phoneOnly && !hasUx phoneOnly)
      "phone-camera helper must install when meeting UX is disabled")
    (check (!hasPkg uxOnly pkgs.zoom-us && !hasPhone uxOnly && hasUx uxOnly)
      "meeting UX must not imply Zoom or camera installation")
    (check (hasPkg all pkgs.zoom-us && hasPhone all && hasUx all)
      "independent app toggles must compose with meeting UX")
    (check (lib.hasInfix "meeting-teams-controls" all.xdg.configFile."hypr/custom.d/meeting.conf".text)
      "Teams rules must appear only when selected")
    (check (!lib.hasInfix "meeting-teams-controls" uxOnly.xdg.configFile."hypr/custom.d/meeting.conf".text)
      "Teams rules must not appear when disabled")
  ];
in
pkgs.runCommand "check-meeting-ownership" { } ''
  ${evaluated}
  touch "$out"
''
