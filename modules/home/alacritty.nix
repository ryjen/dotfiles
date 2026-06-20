{ lib, config, ... }:
let
  adoptedProfiles = {
    empty = ../../files/home/.config/alacritty/adopted.d/empty.toml;
    dubnium = ../../files/home/.config/alacritty/adopted.d/dubnium.toml;
  };

  importPaths = [
    "conf.d/base.toml"
    "adopted.d/machine.toml"
    "local.toml"
    "custom.d/00-empty.toml"
    "custom.d/00-local.toml"
    "custom.d/10-font.toml"
    "custom.d/20-colors.toml"
    "custom.d/90-local.toml"
  ];

  renderedImports = lib.concatMapStringsSep "\n" (path: ''
        "${path}",
  '') importPaths;
in
{
  options.dotfiles.alacritty.adoptedProfile = lib.mkOption {
    type = lib.types.enum (builtins.attrNames adoptedProfiles);
    default = "empty";
    description = "Machine-specific Alacritty profile fragment to import into the generated config.";
  };

  config = lib.mkIf config.dotfiles.profiles.workstation.enable {
    xdg.configFile."alacritty/alacritty.toml".text = ''
      # GENERATED FILE — DO NOT EDIT DIRECTLY
      # source-of-truth: ryjen/dotfiles
      # base-layer: ~/.config/alacritty/conf.d/base.toml
      # local-layer: ~/.config/alacritty/local.toml
      # custom-layer: ~/.config/alacritty/custom.d/*.toml
      # adopted-layer: ~/.config/alacritty/adopted.d/*
      #
      # Alacritty imports are explicit paths, not Hyprland-style globs.
      # Missing imports are skipped, so custom fragments can be created
      # locally using the filenames listed below.

      [general]
      import = [
      ${renderedImports}
      ]
    '';

    xdg.configFile."alacritty/conf.d/base.toml".source = ../../files/home/.config/alacritty/conf.d/base.toml;
    xdg.configFile."alacritty/adopted.d/machine.toml".source = adoptedProfiles.${config.dotfiles.alacritty.adoptedProfile};
    xdg.configFile."alacritty/custom.d/00-empty.toml".source = ../../files/home/.config/alacritty/custom.d/empty.toml;
  };
}
