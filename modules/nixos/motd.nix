{ ... }:
{
  users.motd = builtins.readFile ../../collections/ansible_collections/ryjen/dotfiles/roles/motd/files/motd;
}
