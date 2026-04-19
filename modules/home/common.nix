{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bottom
    gdu
    ripgrep
    fd
    lazygit
    lazydocker
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
