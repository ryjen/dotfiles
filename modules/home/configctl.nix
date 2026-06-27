{
  lib,
  config,
  ...
}:
let
  contractsDir = ../../contracts/configctl/init;
  contractFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".toml" name) (
    builtins.readDir contractsDir
  );
  enabledContractFiles = lib.filterAttrs (
    name: _type:
    name != "hermes-config.toml" || config.dotfiles.agents.hermes.enable
  ) contractFiles;
in
{
  xdg.configFile = lib.mapAttrs' (name: _type: {
    name = "configctl/init.d/${name}";
    value = {
      source = "${contractsDir}/${name}";
    };
  }) enabledContractFiles;
}
