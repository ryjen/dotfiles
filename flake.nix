{
  description = "ryjen dotfiles with incremental NixOS and Home Manager migration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-agent.url = "github:NousResearch/hermes-agent";
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      hermes-agent,
      antigravity-nix,
      sops-nix,
      git-hooks,
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
            inherit self username hermes-agent antigravity-nix;
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
            inherit self username hermes-agent antigravity-nix;
          };
          modules = [
            ./hosts/nixos/configuration.nix
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit self username hermes-agent antigravity-nix;
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
    in
    {
      apps.${system} = {
        verify-container = {
          type = "app";
          program = "${./scripts/verify-in-container.sh}";
        };

        verify-session-files = {
          type = "app";
          program = "${./scripts/verify-session-files.sh}";
        };

        verify-neovim-config = {
          type = "app";
          program = "${./scripts/verify-neovim-config.sh}";
        };
      };

      checks.${system} = {
        flake-script-executables =
          pkgs.runCommand "flake-script-executables" { nativeBuildInputs = [ pkgs.git ]; }
            ''
              ${./scripts/verify-flake-script-executables.sh} ${self}
              touch "$out"
            '';

        pre-commit-check = git-hooks.lib.${system}.run {
          src = self;
          hooks = {
            nixfmt.enable = true;
          };
        };
      };

      devShells.${system}.default =
        let
          inherit (self.checks.${system}.pre-commit-check) shellHook enabledPackages;
        in
        pkgs.mkShell {
          inherit shellHook;
          buildInputs = enabledPackages;
        };

      packages.${system} = {
        hermes-agent = hermes-agent.packages.${system}.default;
      };

      nixosConfigurations.nixos = mkNixosConfig ./home/ryjen/home.nix;
      nixosConfigurations.verify = mkNixosConfig ./home/ryjen/verify-home.nix;

      homeConfigurations."${username}@nixos" = mkHomeConfig ./home/ryjen/home.nix;
      homeConfigurations."${username}@verify" = mkHomeConfig ./home/ryjen/verify-home.nix;
      homeConfigurations."${username}@headless" = mkHomeConfig ./home/ryjen/headless-home.nix;
      homeConfigurations."${username}@wsl" = mkHomeConfig ./home/ryjen/wsl-home.nix;
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
            inherit self hermes-agent antigravity-nix;
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
