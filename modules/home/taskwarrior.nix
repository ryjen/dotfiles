{
  pkgs,
  ...
}:
{
  home.packages = [
    (pkgs.taskwarrior3 or pkgs.taskwarrior)
  ];

  home.file.".taskrc".source =
    ../../collections/ansible_collections/ryjen/dotfiles/roles/taskwarrior/files/dotfiles/.taskrc;
}
