{
  pkgs,
  ...
}:
{
  home.packages = [
    pkgs.zsh
    pkgs.zsh-autosuggestions
  ];

  home.sessionPath = [
    "$HOME/.local/bin"
    "/usr/local/bin"
  ];

  home.file.".zshenv".text = ''
    export ZDOTDIR="$HOME/.config/zsh"
  '';

  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history.path = "$HOME/.config/zsh/.zsh_history";
    initContent = ''
      USE_POWERLINE="true"
      HAS_WIDECHARS="false"

      [ -d ~/.config/zsh/config.d/ ] && source <(cat ~/.config/zsh/config.d/*)

      alias ssh="TERM=xterm-256color ssh"

      if [ -f ~/.config/user-dirs.dirs ]; then
        source ~/.config/user-dirs.dirs
      fi
    '';
    loginExtra = ''
      {
        zcompdump="''${ZDOTDIR:-$HOME}/.zcompdump"
        if [[ -s "$zcompdump" && (! -s "''${zcompdump}.zwc" || "$zcompdump" -nt "''${zcompdump}.zwc") ]]; then
          zcompile "$zcompdump"
        fi
      } &!
    '';
  };
}
