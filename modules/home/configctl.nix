{
  lib,
  ...
}:
let
  contractsDir = ../../contracts/configctl/init;
  contractFiles = lib.filterAttrs (
    name: type: type == "regular" && lib.hasSuffix ".toml" name
  ) (builtins.readDir contractsDir);
in
{
  xdg.configFile = lib.mapAttrs' (name: _type: {
    name = "configctl/init.d/${name}";
    value = { source = "${contractsDir}/${name}"; };
  }) contractFiles;
}
