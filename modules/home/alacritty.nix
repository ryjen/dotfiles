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
in
{
  options.dotfiles.alacritty.adoptedProfile = lib.mkOption {
    type = lib.types.enum (builtins.attrNames adoptedProfiles);
    default = "empty";
    description = "Machine-specific Alacritty profile fragment to import into the generated config.";
  };

  config = lib.mkIf config.dotfiles.profiles.workstation.enable {
    # Keep package enablement and ~/.config/alacritty/alacritty.toml
    # ownership on the Home Manager Alacritty module. The generated entrypoint
    # only imports layered TOML fragments; concrete settings live below conf.d,
    # adopted.d, local.toml, and custom.d.
    programs.alacritty = {
      enable = true;
      settings = {
        general.import = importPaths;
      };
    };

    xdg.configFile."alacritty/conf.d/base.toml".source =
      ../../files/home/.config/alacritty/conf.d/base.toml;
    xdg.configFile."alacritty/adopted.d/machine.toml".source =
      adoptedProfiles.${config.dotfiles.alacritty.adoptedProfile};
    xdg.configFile."alacritty/custom.d/00-empty.toml".source =
      ../../files/home/.config/alacritty/custom.d/empty.toml;
  };
}
