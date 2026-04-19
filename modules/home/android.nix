{ pkgs, ... }:
{
  home.packages = with pkgs; [
    android-studio
    android-tools
  ];

  # Android-specific zsh config
  xdg.configFile."zsh/config.d/android".source = ../../collections/ansible_collections/ryjen/dotfiles/roles/android/files/dotfiles/.config/zsh/config.d/android;

  # Android control script
  home.file.".local/bin/droidctl" = {
    source = ../../collections/ansible_collections/ryjen/dotfiles/roles/android/files/dotfiles/.local/bin/droidctl;
    executable = true;
  };
}
