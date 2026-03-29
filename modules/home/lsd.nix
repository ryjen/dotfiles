{
  pkgs,
  ...
}:
{
  home.packages = [
    pkgs.lsd
  ];

  home.shellAliases = {
    ls = "lsd";
  };
}
