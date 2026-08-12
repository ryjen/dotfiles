{
  lib,
  pkgs,
  config,
  ...
}:
let
  unsignedRegistryPolicy = lib.genAttrs config.dotfiles.podman.allowedUnsignedRegistries (_: [
    {
      type = "insecureAcceptAnything";
    }
  ]);
in
{
  options.dotfiles = {
    host = {
      name = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Optional Home Manager host identity.";
      };

      role = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Optional Home Manager host role.";
      };

      graphical.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether this Home Manager profile is graphical-capable.";
      };

      laptop.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether this Home Manager profile is laptop-specific.";
      };

      wsl.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether this Home Manager profile targets WSL.";
      };

      userSystemd.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether this host supports Home Manager user systemd units.";
      };
    };

    sshAgent.enable = lib.mkOption {
      type = lib.types.bool;
      default = config.dotfiles.host.userSystemd.enable;
      defaultText = lib.literalExpression "config.dotfiles.host.userSystemd.enable";
      description = "Whether to run the Home Manager OpenSSH agent as a user systemd service.";
    };

    podman = {
      apiSocket.enable = lib.mkEnableOption "the rootless Podman API socket";

      allowedUnsignedRegistries = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "docker.io"
          "ghcr.io"
        ];
        description = ''
          Fully qualified registries temporarily permitted without signature
          verification. Unspecified registries are rejected by default.
        '';
      };
    };
  };

  config = {
    assertions = [
      {
        assertion = !config.dotfiles.sshAgent.enable || config.dotfiles.host.userSystemd.enable;
        message = "dotfiles.sshAgent.enable requires Home Manager user systemd support.";
      }
    ];

    services.ssh-agent.enable = config.dotfiles.sshAgent.enable;

    home.packages = with pkgs; [
      bottom
      gdu
      ripgrep
      fd
      gnumake
      lazygit
      podman
      podman-compose
      tig
      sad
      jq
      yq-go
      htop
      curl
      wget
      autojump
      keychain
      unzip
      zip
      tree
      tree-sitter
    ];

    xdg.configFile."containers/registries.conf".text = ''
      unqualified-search-registries = []
      short-name-mode = "enforcing"
    '';

    xdg.configFile."containers/policy.json".text = builtins.toJSON {
      default = [
        {
          type = "reject";
        }
      ];
      transports = {
        docker = unsignedRegistryPolicy;
        "containers-storage" = {
          "" = [
            {
              type = "insecureAcceptAnything";
            }
          ];
        };
      };
    };

    systemd.user.sockets.podman = lib.mkIf (
      config.dotfiles.host.userSystemd.enable && config.dotfiles.podman.apiSocket.enable
    ) {
      Unit = {
        Description = "Podman API Socket";
        Documentation = [ "man:podman-system-service(1)" ];
      };
      Socket.ListenStream = "%t/podman/podman.sock";
      Install.WantedBy = [ "sockets.target" ];
    };

    systemd.user.services.podman = lib.mkIf (
      config.dotfiles.host.userSystemd.enable && config.dotfiles.podman.apiSocket.enable
    ) {
      Unit = {
        Description = "Podman API Service";
        Requires = [ "podman.socket" ];
        After = [ "podman.socket" ];
        Documentation = [ "man:podman-system-service(1)" ];
      };
      Service = {
        Type = "exec";
        ExecStart = "${pkgs.podman}/bin/podman system service";
      };
    };

    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
