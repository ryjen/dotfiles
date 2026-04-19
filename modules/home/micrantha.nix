{ ... }:
{
  # Micrantha-specific dotfiles
  
  # SSH Config
  home.file.".ssh/config.d/micrantha".source = ../../collections/ansible_collections/ryjen/dotfiles/roles/micrantha/files/dotfiles/.ssh/config;
  home.file.".ssh/conf.d" = {
    source = ../../collections/ansible_collections/ryjen/dotfiles/roles/micrantha/files/dotfiles/.ssh/conf.d;
    recursive = true;
  };

  # Git Config
  home.file.".config/git/conf.d/micrantha".source = ../../collections/ansible_collections/ryjen/dotfiles/roles/micrantha/files/dotfiles/.config/git/conf.d/micrantha;

  # Zsh Config
  home.file.".config/zsh/config.d/micrantha".source = ../../collections/ansible_collections/ryjen/dotfiles/roles/micrantha/files/dotfiles/.config/zsh/micrantha;
}
