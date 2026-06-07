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

    xdg.configFile."zsh/config.d/android".source = ../../files/home/.config/zsh/config.d/android;

    home.file.".local/bin/droidctl" = {
      source = ../../files/home/.local/bin/droidctl;
      executable = true;
    };
  };
}
