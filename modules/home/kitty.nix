{ lib, config, pkgs, ... }:
let
  adoptedProfiles = {
    empty = ../../files/home/.config/kitty/adopted.d/empty.conf;
    dubnium = ../../files/home/.config/kitty/adopted.d/dubnium.conf;
  };

  machineProfile = config.dotfiles.host.name;
  machineProfileName = if machineProfile == null then "unconfigured" else machineProfile;
  kittyCustomProfilesRoot = ../../files/home/.config/kitty/custom.d;
  kittyCustomProfile = kittyCustomProfilesRoot + "/${machineProfileName}";
  hasKittyCustomProfile = machineProfile != null && builtins.pathExists kittyCustomProfile;
in
{
  options.dotfiles.kitty.adoptedProfile = lib.mkOption {
    type = lib.types.enum (builtins.attrNames adoptedProfiles);
    default = "empty";
    description = "Machine-specific Kitty profile fragment retained for adopted/archive configuration.";
  };

  config = lib.mkIf config.dotfiles.profiles.workstation.enable {
    # Home Manager owns Kitty and ~/.config/kitty/kitty.conf. configctl owns the
    # reviewed custom/adoption workflow; Home Manager only materializes promoted
    # profile fragments back into the runtime tree.
    programs.kitty = {
      enable = true;
      extraConfig = ''
        include conf.d/base.conf
        include adopted.d/machine.conf
        globinclude custom.d/${machineProfileName}/*.conf
        globinclude custom.d/*.conf
        include local.conf
      '';
    };

    xdg.configFile = {
      "kitty/conf.d/base.conf".source =
        ../../files/home/.config/kitty/conf.d/base.conf;
      "kitty/adopted.d/machine.conf".source =
        adoptedProfiles.${config.dotfiles.kitty.adoptedProfile};
      "kitty/custom.d/00-empty.conf".source =
        ../../files/home/.config/kitty/custom.d/empty.conf;
    }
    // lib.optionalAttrs hasKittyCustomProfile {
      # configctl promote stores reviewed fragments under
      # files/home/.config/kitty/custom.d/<profile>/. Project that profile back
      # into the runtime tree without taking ownership of root custom.d/*.conf.
      "kitty/custom.d/${machineProfileName}" = {
        source = kittyCustomProfile;
        recursive = true;
      };
    };

    home.activation.ensureKittyLocalConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      local_config="$HOME/.config/kitty/local.conf"
      if [ ! -e "$local_config" ]; then
        ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$local_config")"
        ${pkgs.coreutils}/bin/printf '%s\n' '# Place host-local or user overrides here.' > "$local_config"
      fi
    '';
  };
}
