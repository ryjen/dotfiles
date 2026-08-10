{
  config,
  lib,
  ...
}:
let
  cfg = config.dotfiles.waybar;
  presentationOutput = config.dotfiles.meeting.presentationOutput;
  templates = {
    workstation = ../../files/home/.config/waybar/config.jsonc;
    laptop = ../../files/home/.config/waybar/config-technetium.jsonc;
  };
  normalOutputs =
    if presentationOutput == null then
      [ "*" ]
    else
      [
        "!${presentationOutput}"
        "*"
      ];
  presentationOnlyOutput =
    if presentationOutput == null then "DUBNIUM/NO-PRESENTATION-OUTPUT" else presentationOutput;
  renderedConfig =
    builtins.replaceStrings
      [ "__DUBNIUM_NORMAL_OUTPUTS__" "__DUBNIUM_PRESENTATION_OUTPUT__" ]
      [ (builtins.toJSON normalOutputs) (builtins.toJSON presentationOnlyOutput) ]
      (builtins.readFile templates.${cfg.variant});
in
{
  options.dotfiles.waybar.variant = lib.mkOption {
    type = lib.types.enum (builtins.attrNames templates);
    default = "workstation";
    description = "Waybar hardware module variant.";
  };

  config = lib.mkIf config.dotfiles.profiles.workstation.enable {
    xdg.configFile."waybar/config.jsonc".text = renderedConfig;
    xdg.configFile."waybar/style.css".source = ../../files/home/.config/waybar/style.css;
    xdg.configFile."waybar/colors.css".source = ../../files/home/.config/waybar/colors.css;
    xdg.configFile."waybar/custom.css".source = ../../files/home/.config/waybar/custom.css;
    xdg.configFile."waybar/scripts/fans" = {
      source = ../../files/home/.config/waybar/scripts/fans;
      executable = true;
    };
    xdg.configFile."waybar/scripts/nvidia-gpu" = {
      source = ../../files/home/.config/waybar/scripts/nvidia-gpu;
      executable = true;
    };
    xdg.configFile."waybar/scripts/disk-space" = {
      source = ../../files/home/.config/waybar/scripts/disk-space;
      executable = true;
    };
    xdg.configFile."waybar/scripts/bluetooth" = {
      source = ../../files/home/.config/waybar/scripts/bluetooth;
      executable = true;
    };

    # Own the systemd unit via Home Manager instead of the package-provided one.
    # The package unit hard-codes `Requisite=graphical-session.target`, which is
    # dead in sessions launched directly via greetd -> start-hyprland (UWSM, the
    # only thing that raises that target, is bypassed). With a dead Requisite the
    # service can never start. HM's unit has no Requisite; we tie it to
    # default.target (always active at login) so the bar comes up independently
    # of the broken graphical-session.target, while ConditionEnvironment keeps
    # it Wayland-only. This also stops the package's auto-linked unit from
    # colliding with ours at ~/.config/systemd/user/waybar.service.
    programs.waybar = {
      enable = true;
      systemd.enable = true;
      systemd.targets = [ "default.target" ];
    };
  };
}
