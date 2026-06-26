{
  lib,
  ...
}:
{
  home.file.".config/configctl/init.d/npm-globals.toml".source =
    ../../contracts/configctl/init/npm-globals.toml;
}
