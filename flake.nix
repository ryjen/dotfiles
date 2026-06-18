{
  description = "ryjen dotfiles with incremental NixOS and Home Manager migration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
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
      verifySessionFiles = pkgs.writeShellApplication {
        name = "verify-session-files";
        runtimeInputs = [
          pkgs.bash
          pkgs.coreutils
        ];
        text = ''
          exec ${pkgs.runtimeShell} ${./scripts/verify-session-files.sh} "$@"
        '';
      };
    in
    {
      apps.${system} = {
        verify-container = {
          type = "app";
          program = "${verifyInContainer}/bin/verify-in-container";
        };

        verify-session-files = {
          type = "app";
          program = "${verifySessionFiles}/bin/verify-session-files";
        };
      };

      packages.${system} = {
        verify-container = verifyInContainer;
        verify-session-files = verifySessionFiles;
        hermes-agent = hermes-agent.packages.${system}.default;
      };

      nixosConfigurations.nixos = mkNixosConfig ./home/ryjen/home.nix;
      nixosConfigurations.verify = mkNixosConfig ./home/ryjen/verify-home.nix;

      homeConfigurations."${username}@nixos" = mkHomeConfig ./home/ryjen/home.nix;
      homeConfigurations."${username}@verify" = mkHomeConfig ./home/ryjen/verify-home.nix;
      homeConfigurations."${username}@dubnium" = mkHomeConfig ./home/ryjen/dubnium-home.nix;
      homeConfigurations."${username}@technetium" = mkHomeConfig ./home/ryjen/technetium-home.nix;

      nixosModules.dubnium-home-manager =
        {
          config,
          ...
        }:
        let
          dubniumUsername = config.dubnium.user.name or username;
        in
        {
          imports = [
            home-manager.nixosModules.home-manager
          ];

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {
            inherit self hermes-agent;
            username = dubniumUsername;
          };
          home-manager.users.${dubniumUsername} = {
            imports = [
              ./home/ryjen/dubnium-home.nix
              sops-nix.homeManagerModules.sops
            ];
          };
        };
    };
}
