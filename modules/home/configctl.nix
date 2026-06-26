{
  lib,
  ...
}:
{
  xdg.configFile."configctl/init.d/npm-globals.toml".source =
    ../../contracts/configctl/init/npm-globals.toml;
}
