{
  pkgs,
  ...
}:
{
  home.packages = [
    (pkgs.taskwarrior3 or pkgs.taskwarrior)
  ];

  home.file = {
    ".taskrc".source = ../../files/home/.taskrc;

    ".config/task".source = ../../files/home/.config/task;
  };
}
