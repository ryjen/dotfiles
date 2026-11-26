{
  pkgs,
  home-manager,
  self,
}:
let
  inherit (pkgs) lib;
  evalMeeting =
    {
      meeting ? false,
      desktop ? false,
      zoom ? false,
      teams ? false,
      phone ? false,
    }:
    (home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ../modules/home/meeting.nix
        ({ lib, ... }: {
          options.dotfiles.profiles.workstation.enable = lib.mkOption {
            type = lib.types.bool;
            default = desktop;
          };
          options.dotfiles.host.graphical.enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
          options.dotfiles.host.userSystemd.enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
          config = {
            home = {
              username = "camera-test";
              homeDirectory = "/home/camera-test";
              stateVersion = "25.05";
            };
            dotfiles.meeting = {
              enable = meeting;
              zoom.enable = zoom;
              teams.enable = teams;
              phoneCamera.enable = phone;
            };
          };
        })
      ];
    }).config;
  none = evalMeeting { };
  desktopOnly = evalMeeting { desktop = true; };
  zoomOnly = evalMeeting { zoom = true; };
  phoneOnly = evalMeeting { phone = true; };
  uxOnly = evalMeeting { meeting = true; };
  all = evalMeeting {
    meeting = true;
    zoom = true;
    teams = true;
    phone = true;
  };
  workstation = self.homeConfigurations."ryjen@dubnium".config;
  laptop = self.homeConfigurations."ryjen@technetium".config;
  hasPkg = cfg: pkg: builtins.elem (toString pkg) (map toString cfg.home.packages);
  hasPhone = cfg: builtins.hasAttr ".local/bin/dubctl-phone-camera" cfg.home.file;
  hasUx = cfg: builtins.hasAttr "hypr/custom.d/meeting.conf" cfg.xdg.configFile;
  hasDesktopTools = cfg:
    builtins.hasAttr ".local/bin/dub-obs-hotkey" cfg.home.file
    && builtins.hasAttr ".local/libexec/dubnium-eww-quote-overlay" cfg.home.file
    && builtins.hasAttr ".local/bin/dub-eww-quote-overlay" cfg.home.file
    && builtins.hasAttr "hypr/custom.d/obs-hotkeys.conf" cfg.xdg.configFile
    && builtins.hasAttr "dubnium/meeting/obs-init.json" cfg.xdg.configFile
    && builtins.hasAttr "dubnium/obs/v1" cfg.xdg.dataFile;
  check = condition: message: if condition then "" else builtins.throw message;
  evaluated = builtins.concatStringsSep "" [
    (check (
      workstation.dotfiles.meeting.zoom.enable
      && workstation.dotfiles.meeting.teams.enable
      && workstation.dotfiles.meeting.phoneCamera.enable
      && hasPkg workstation pkgs.zoom-us
      && hasPhone workstation
    ) "Dubnium workstation must retain Zoom, Teams and the phone camera helper")
    (check (
      laptop.dotfiles.meeting.zoom.enable
      && laptop.dotfiles.meeting.teams.enable
      && laptop.dotfiles.meeting.phoneCamera.enable
      && hasPkg laptop pkgs.zoom-us
      && hasPhone laptop
    ) "Technetium laptop must retain Zoom, Teams and the phone camera helper")
    (check (
      !hasPkg none pkgs.zoom-us && !hasPhone none && !hasUx none
    ) "disabled meeting must install neither optional apps nor meeting UX")
    (check (
      hasDesktopTools desktopOnly
      && !hasUx desktopOnly
      && !(builtins.hasAttr "dubnium-meeting-mode" desktopOnly.systemd.user.services)
      && !(builtins.hasAttr "dubnium-cliphist" desktopOnly.systemd.user.services)
    ) "Desktop OBS/Eww tools must work without enabling meeting privacy or clipboard capture")
    (check (
      !hasDesktopTools none && hasDesktopTools uxOnly
    ) "Non-desktop defaults must remain unchanged and existing meeting tools retained")
    (check (
      hasPkg zoomOnly pkgs.zoom-us && !hasPhone zoomOnly && !hasUx zoomOnly
    ) "Zoom must install when meeting UX is disabled")
    (check (
      !hasPkg phoneOnly pkgs.zoom-us && hasPhone phoneOnly && !hasUx phoneOnly
    ) "phone-camera helper must install when meeting UX is disabled")
    (check (
      !hasPkg uxOnly pkgs.zoom-us && !hasPhone uxOnly && hasUx uxOnly
    ) "meeting UX must not imply Zoom or camera installation")
    (check (
      hasPkg all pkgs.zoom-us && hasPhone all && hasUx all
    ) "independent app toggles must compose with meeting UX")
    (check (lib.hasInfix "meeting-teams-controls"
      all.xdg.configFile."hypr/custom.d/meeting.conf".text
    ) "Teams rules must appear only when selected")
    (check (
      !lib.hasInfix "meeting-teams-controls" uxOnly.xdg.configFile."hypr/custom.d/meeting.conf".text
    ) "Teams rules must not appear when disabled")
  ];
in
pkgs.runCommand "check-meeting-ownership" { } ''
  ${evaluated}
  touch "$out"
''
