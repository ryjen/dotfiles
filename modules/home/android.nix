{
  lib,
  pkgs,
  config,
  ...
}:
{
  options.dotfiles.profiles.android.enable = lib.mkEnableOption "Android tooling overlay";

  config = lib.mkIf config.dotfiles.profiles.android.enable {
    home.packages = with pkgs; [
      android-studio
      android-tools
    ];

    # Keep optional Android agent tooling out of Home Manager activation until
    # it is available as a pinned, integrity-verified Nix package. Activation
    # must not download mutable executables into the user's home directory.

    xdg.configFile."zsh/config.d/android".source = ../../files/home/.config/zsh/config.d/android;

    home.file.".local/bin/droidctl" = {
      source = ../../files/home/.local/bin/droidctl;
      executable = true;
    };
  };
}
