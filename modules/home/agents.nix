{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodejs
  ];

  # Agents configuration and skills
  home.file.".agents" = {
    source = ../../collections/ansible_collections/ryjen/dotfiles/roles/agents/files/dotfiles/.agents;
    recursive = true;
  };

  home.file.".codex" = {
    source = ../../collections/ansible_collections/ryjen/dotfiles/roles/agents/files/dotfiles/.codex;
    recursive = true;
  };
}
