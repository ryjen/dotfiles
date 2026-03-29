{
  pkgs,
  ...
}:
{
  home.packages = [
    pkgs.ansible
  ];

  home.file.".ansible.cfg".source =
    ../../collections/ansible_collections/ryjen/dotfiles/roles/ansible/files/dotfiles/.ansible.cfg;
}
