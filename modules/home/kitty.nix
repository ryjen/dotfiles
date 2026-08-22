{ lib, config, pkgs, ... }:
let
  adoptedProfiles = {
    empty = ../../files/home/.config/kitty/adopted.d/empty.conf;
    dubnium = ../../files/home/.config/kitty/adopted.d/dubnium.conf;
  };
in
{
  options.dotfiles.kitty.adoptedProfile = lib.mkOption {
    type = lib.types.enum (builtins.attrNames adoptedProfiles);
    default = "empty";
    description = "Machine-specific Kitty profile fragment to import into the generated config.";
  };

  config = lib.mkIf config.dotfiles.profiles.workstation.enable {
    # Home Manager owns Kitty and ~/.config/kitty/kitty.conf. The generated
    # entrypoint only composes managed, adopted, local, and custom layers.
    programs.kitty = {
      enable = true;
      extraConfig = ''
        include conf.d/base.conf
        include adopted.d/machine.conf
        include local.conf
        globinclude custom.d/*.conf
      '';
    };

    xdg.configFile."kitty/conf.d/base.conf".source =
      ../../files/home/.config/kitty/conf.d/base.conf;
    xdg.configFile."kitty/adopted.d/machine.conf".source =
      adoptedProfiles.${config.dotfiles.kitty.adoptedProfile};
    xdg.configFile."kitty/custom.d/00-empty.conf".source =
      ../../files/home/.config/kitty/custom.d/empty.conf;

    home.activation.ensureKittyLocalConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      local_config="$HOME/.config/kitty/local.conf"
      if [ ! -e "$local_config" ]; then
        ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$local_config")"
        ${pkgs.coreutils}/bin/printf '%s\n' '# Place host-local or user overrides here.' > "$local_config"
      fi
    '';
  };
}
