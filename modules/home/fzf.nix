{
  pkgs,
  ...
}:
{
  home.packages = [
    pkgs.fd
  ];

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--layout reverse"
      "--info inline"
      "--border"
      "--preview 'bat --style=numbers --color=always --line-range :500 {} 2>/dev/null'"
    ];
  };
}
