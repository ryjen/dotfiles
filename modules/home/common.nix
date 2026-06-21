{
  lib,
  pkgs,
  config,
  ...
}:
{
  options.dotfiles.host.userSystemd.enable = lib.mkEnableOption "Home Manager user systemd units" // {
    default = true;
  };

  config = {
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
      unqualified-search-registries = ["docker.io"]
    '';

    xdg.configFile."containers/policy.json".text = builtins.toJSON {
      default = [
        {
          type = "insecureAcceptAnything";
        }
      ];
    };

    systemd.user.sockets.podman = lib.mkIf config.dotfiles.host.userSystemd.enable {
      Unit = {
        Description = "Podman API Socket";
        Documentation = [ "man:podman-system-service(1)" ];
      };
      Socket.ListenStream = "%t/podman/podman.sock";
      Install.WantedBy = [ "sockets.target" ];
    };

    systemd.user.services.podman = lib.mkIf config.dotfiles.host.userSystemd.enable {
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
