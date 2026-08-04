{
  description = "ryjen dotfiles with incremental NixOS and Home Manager migration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ops-cadence = {
      url = "git+ssh://git@github.com/ryjen/ops-cadence.git?ref=main&rev=d83511cb669a6ca1481f7a79ea5f1aac6ceabd36";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-autocommit = {
      url = "github:ryjen/git-autocommit";
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
      ops-cadence,
      git-autocommit,
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
            inherit
              self
              username
              hermes-agent
              antigravity-nix
              ops-cadence
              git-autocommit
              ;
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
            inherit
              self
              username
              hermes-agent
              antigravity-nix
              ops-cadence
              git-autocommit
              ;
          };
          modules = [
            ./hosts/nixos/configuration.nix
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit
                  self
                  username
                  hermes-agent
                  antigravity-nix
                  ops-cadence
                  git-autocommit
                  ;
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
        benchmark-dubnium = {
          type = "app";
          program = "${pkgs.writeShellScript "benchmark-dubnium" ''
            exec ${pkgs.python3}/bin/python3 ${./scripts/benchmark-nix-build.py} "$@"
          ''}";
        };

        verify-container = {
          type = "app";
          program = "${./scripts/verify-in-container.sh}";
        };

        verify-session-files = {
          type = "app";
          program = "${pkgs.writeShellScript "verify-session-files" ''
            exec ${pkgs.bash}/bin/bash ${./scripts/verify-session-files.sh} "$@"
          ''}";
        };

        verify-neovim-config = {
          type = "app";
          program = "${pkgs.writeShellScript "verify-neovim-config" ''
            exec ${pkgs.bash}/bin/bash ${./scripts/verify-neovim-config.sh} "$@"
          ''}";
        };

        verify-configctl-contracts = {
          type = "app";
          program = "${pkgs.writeShellScript "verify-configctl-contracts" ''
            exec ${pkgs.python3}/bin/python3 ${./checks/verify-configctl-contracts.py} ${self}
          ''}";
        };
      };

      checks.${system} = {
        benchmark-nix-build-tests =
          pkgs.runCommand "benchmark-nix-build-tests" { nativeBuildInputs = [ pkgs.python3 ]; }
            ''
              export PYTHONDONTWRITEBYTECODE=1
              cd ${self}
              python3 -m unittest discover -s tests -p 'test_benchmark_nix_build.py'
              touch "$out"
            '';

        flake-script-executables =
          pkgs.runCommand "flake-script-executables"
            {
              nativeBuildInputs = [
                pkgs.bash
                pkgs.git
              ];
            }
            ''
              bash ${./scripts/verify-flake-script-executables.sh} ${self}
              touch "$out"
            '';

        configctl-contracts =
          pkgs.runCommand "configctl-contracts" { nativeBuildInputs = [ pkgs.python3 ]; }
            ''
              python3 ${./checks/verify-configctl-contracts.py} ${self}
              touch "$out"
            '';

        session-files =
          pkgs.runCommand "session-files"
            {
              nativeBuildInputs = [
                pkgs.bash
                pkgs.python3
              ];
            }
            ''
              bash ${./scripts/verify-session-files.sh} ${self}
              touch "$out"
            '';

        obs-templates =
          pkgs.runCommand "obs-templates"
            {
              nativeBuildInputs = [ pkgs.python3 ];
            }
            ''
              python3 ${./scripts/verify-obs-templates.py} ${self}
              touch "$out"
            '';

        obs-hotkey-helper =
          pkgs.runCommand "obs-hotkey-helper"
            {
              nativeBuildInputs = [
                pkgs.bash
                pkgs.coreutils
                pkgs.jq
              ];
            }
            ''
              bash ${./tests/test-dub-obs-hotkey.sh} ${self}
              touch "$out"
            '';

        meeting-mode-tests =
          pkgs.runCommand "meeting-mode-tests"
            {
              nativeBuildInputs = [
                pkgs.bash
                pkgs.coreutils
                pkgs.jq
                pkgs.python3
                pkgs.util-linux
              ];
            }
            ''
              bash ${./tests/test-meeting-mode.sh} ${self}
              touch "$out"
            '';

        git-autocommit-package = git-autocommit.checks.${system}.default;

        pre-commit-check = git-hooks.lib.${system}.run {
          src = self;
          hooks = {
            # Nix
            nixfmt.enable = true;
            statix.enable = true;
            deadnix.enable = true;

            # Shell
            shellcheck.enable = true;
            shfmt.enable = true;

            # Git / file integrity
            check-merge-conflicts.enable = true;
            check-added-large-files.enable = true;
            check-case-conflicts.enable = true;
            check-json.enable = true;
            check-toml.enable = true;
            check-yaml.enable = true;
            end-of-file-fixer.enable = true;
            trim-trailing-whitespace.enable = true;
            mixed-line-endings.enable = true;
            detect-private-keys.enable = true;
            check-symlinks.enable = true;
            check-executables-have-shebangs.enable = true;
            forbid-new-submodules.enable = true;
            no-commit-to-branch.enable = true;

            # Spelling
            typos.enable = true;

            # GitHub Actions
            actionlint.enable = true;
          };
        };
      };

      devShells.${system}.default =
        let
          inherit (self.checks.${system}.pre-commit-check) shellHook enabledPackages;
          prePushHook = pkgs.writeShellScriptBin "pre-push-hook" (
            builtins.readFile ./scripts/pre-push-hook.sh
          );
          hardenHooks = pkgs.writeShellScriptBin "harden-pre-commit-hooks" (
            builtins.readFile ./scripts/harden-pre-commit-hooks.sh
          );
        in
        pkgs.mkShell {
          shellHook = shellHook + ''
            if git rev-parse --git-dir &>/dev/null; then
              # Resolve the real git hooks dir so this works for standalone
              # checkouts and submodules alike.
              git_hook_dir="$(git rev-parse --path-format=absolute --git-common-dir)/hooks"
              # Keep pre-commit-installed hooks working after store GC.
              ${hardenHooks}/bin/harden-pre-commit-hooks "$git_hook_dir"
              # Install custom pre-push hook (WIP, tag, submodule checks)
              mkdir -p "$git_hook_dir"
              cp -f ${prePushHook}/bin/pre-push-hook "$git_hook_dir/pre-push"
              chmod +x "$git_hook_dir/pre-push"
            fi
          '';
          buildInputs = enabledPackages;
        };

      packages.${system} = {
        hermes-agent = hermes-agent.packages.${system}.default;
        git-autocommit = git-autocommit.packages.${system}.default;
        openwork = pkgs.callPackage ./packages/openwork.nix { };
      };

      nixosConfigurations.nixos = mkNixosConfig ./home/ryjen/home.nix;
      nixosConfigurations.verify = mkNixosConfig ./home/ryjen/verify-home.nix;

      homeConfigurations."${username}@nixos" = mkHomeConfig ./home/ryjen/home.nix;
      homeConfigurations."${username}@verify" = mkHomeConfig ./home/ryjen/verify-home.nix;
      homeConfigurations."${username}@headless" = mkHomeConfig ./home/ryjen/headless-home.nix;
      homeConfigurations."${username}@wsl" = mkHomeConfig ./home/ryjen/wsl-home.nix;
      homeConfigurations."${username}@dubnium" = mkHomeConfig ./home/ryjen/dubnium-home.nix;
      homeConfigurations."${username}@technetium" = mkHomeConfig ./home/ryjen/technetium-home.nix;
      homeConfigurations."${username}@meeting-verify" = mkHomeConfig ./home/ryjen/meeting-verify-home.nix;

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
            inherit
              self
              hermes-agent
              antigravity-nix
              ops-cadence
              git-autocommit
              ;
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
