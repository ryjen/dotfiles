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
              home-manager.users = {
                ryjen = {
                  imports = [
                    profileModule
                    sops-nix.homeManagerModules.sops
                  ];
                };
              };
            }
          ];
        };
    in
    {
      apps.x86_64-linux = {
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

      checks.x86_64-linux = {
        flake-script-executables =
          pkgs.runCommand "flake-script-executables" { nativeBuildInputs = [ pkgs.git ]; }
            ''
              ${./scripts/verify-flake-script-executables.sh} ${self}
              touch "$out"
            '';

        pre-commit-check = git-hooks.lib.x86_64-linux.run {
          src = self;
          hooks = {
            nixfmt.enable = true;
          };
        };
      };

      devShells.x86_64-linux.default =
        let
          inherit (self.checks.x86_64-linux.pre-commit-check) shellHook enabledPackages;
        in
        pkgs.mkShell {
          inherit shellHook;
          buildInputs = enabledPackages;
        };

      packages.x86_64-linux = {
        hermes-agent = hermes-agent.packages.x86_64-linux.default;
      };

      nixosConfigurations.nixos = mkNixosConfig ./home/ryjen/home.nix;
      nixosConfigurations.verify = mkNixosConfig ./home/ryjen/verify-home.nix;

      homeConfigurations."ryjen@nixos" = mkHomeConfig ./home/ryjen/home.nix;
      homeConfigurations."ryjen@verify" = mkHomeConfig ./home/ryjen/verify-home.nix;
      homeConfigurations."ryjen@headless" = mkHomeConfig ./home/ryjen/headless-home.nix;
      homeConfigurations."ryjen@wsl" = mkHomeConfig ./home/ryjen/wsl-home.nix;
      homeConfigurations."ryjen@dubnium" = mkHomeConfig ./home/ryjen/dubnium-home.nix;
      homeConfigurations."ryjen@technetium" = mkHomeConfig ./home/ryjen/technetium-home.nix;

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
          home-manager.users = builtins.listToAttrs [
            {
              name = dubniumUsername;
              value = {
                imports = [
                  ./home/ryjen/dubnium-home.nix
                  sops-nix.homeManagerModules.sops
                ];
              };
            }
          ];
        };
    };
}
