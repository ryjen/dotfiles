{
  description = "ryjen dotfiles with incremental NixOS and Home Manager migration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-agent.url = "github:NousResearch/hermes-agent";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      hermes-agent,
      sops-nix,
      ...
    }:
    let
      system = "x86_64-linux";
      username = "ryjen";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      mkHomeConfig =
        profileModule:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit self username hermes-agent;
          };
          modules = [
            profileModule
            sops-nix.homeManagerModules.sops
          ];
        };
      mkNixosConfig =
        profileModule:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit self username hermes-agent;
          };
          modules = [
            ./hosts/nixos/configuration.nix
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit self username hermes-agent;
              };
              home-manager.users.${username} = {
                imports = [
                  profileModule
                  sops-nix.homeManagerModules.sops
                ];
              };
            }
          ];
        };
      verifyInContainer = pkgs.writeShellApplication {
        name = "verify-in-container";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          exec ${pkgs.runtimeShell} ${./scripts/verify-in-container.sh} "$@"
        '';
      };
    in
    {
      apps.${system}.verify-container = {
        type = "app";
        program = "${verifyInContainer}/bin/verify-in-container";
      };

      packages.${system} = {
        verify-container = verifyInContainer;
        hermes-agent = hermes-agent.packages.${system}.default;
      };

      nixosConfigurations.nixos = mkNixosConfig ./home/ryjen/home.nix;
      nixosConfigurations.verify = mkNixosConfig ./home/ryjen/verify-home.nix;

      homeConfigurations."${username}@nixos" = mkHomeConfig ./home/ryjen/home.nix;
      homeConfigurations."${username}@verify" = mkHomeConfig ./home/ryjen/verify-home.nix;
    };
}
