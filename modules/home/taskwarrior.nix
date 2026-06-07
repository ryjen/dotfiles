{
  pkgs,
  ...
}:
{
  home.packages = [
    (pkgs.taskwarrior3 or pkgs.taskwarrior)
  ];

  home.file.".taskrc".source = ../../files/home/.taskrc;
}
