{ ... }:
{
  # Micrantha-specific dotfiles
  
  # SSH Config
  home.file.".ssh/config.d/micrantha".source = ../../files/home/.ssh/config;
  home.file.".ssh/conf.d" = {
    source = ../../files/home/.ssh/conf.d;
    recursive = true;
  };

  # Git Config
  home.file.".config/git/conf.d/micrantha".source = ../../files/home/.config/git/conf.d/micrantha;

  # Zsh Config
  home.file.".config/zsh/config.d/micrantha".source = ../../files/home/.config/zsh/micrantha;
}
