{ pkgs, ... }:
{
  home.packages = with pkgs; [
    android-studio
    android-tools
  ];

  # Android-specific zsh config
  xdg.configFile."zsh/config.d/android".source = ../../files/home/.config/zsh/config.d/android;

  # Android control script
  home.file.".local/bin/droidctl" = {
    source = ../../files/home/.local/bin/droidctl;
    executable = true;
  };
}
