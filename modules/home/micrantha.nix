{
  lib,
  config,
  ...
}:
{
  options.dotfiles.profiles.micrantha.enable = lib.mkEnableOption "Micrantha overlay";

  config = lib.mkIf config.dotfiles.profiles.micrantha.enable {
    home.file.".ssh/config".source = ../../files/home/.ssh/config;
    home.file.".ssh/conf.d" = {
      source = ../../files/home/.ssh/conf.d;
      recursive = true;
    };

    xdg.configFile."git/conf.d/micrantha".source = ../../files/home/.config/git/conf.d/micrantha;
    xdg.configFile."zsh/config.d/micrantha".source = ../../files/home/.config/zsh/micrantha;
  };
}
