{
  description = "CI fixture for the private ops-cadence flake input";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system}.default = pkgs.writeShellScriptBin "opsctl" ''
        echo "ops-cadence CI fixture: execution is outside this repository's test boundary" >&2
        exit 1
      '';
    };
}
