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
  };
}
