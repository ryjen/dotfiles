{ pkgs, ... }:
let
  dockerCompat = pkgs.runCommandLocal "podman-docker-compat" { } ''
    mkdir -p "$out/bin"
    ln -s ${pkgs.podman}/bin/podman "$out/bin/docker"
  '';
in
{
  home.packages = with pkgs; [
    bottom
    dockerCompat
    gdu
    ripgrep
    fd
    lazygit
    lazydocker
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

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
