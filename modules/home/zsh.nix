{
  pkgs,
  ...
}:
{
  home.file.".zshenv".text = ''
    export ZDOTDIR="$HOME/.config/zsh"
  '';

  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;

    history = {
      size = 100000;
      save = 100000;
      path = "$HOME/.config/zsh/.zsh_history";
      extended = true;
      share = true;
    };

    shellAliases = {
      cat = "bat";
      ssh = "TERM=xterm-256color ssh";
      pbcopy = "wl-copy";
      pbpaste = "wl-paste";
      services = "systemctl list-units --type=service --all";
      k = "kubectl";
      ktl = "kubectl";
      virsh = "virsh --connect qemu:///session";
      open = "xdg-open";
    };

    initContent = ''
      USE_POWERLINE="true"
      HAS_WIDECHARS="false"

      # options
      setopt globdots
      setopt auto_cd
      setopt extended_glob
      setopt hist_ignore_all_dups
      setopt hist_reduce_blanks
      setopt hist_verify
      setopt inc_append_history
      setopt no_bg_nice
      setopt no_case_glob
      setopt no_list_beep

      # keybindings
      autoload -U up-line-or-beginning-search
      autoload -U down-line-or-beginning-search
      zle -N up-line-or-beginning-search
      zle -N down-line-or-beginning-search
      bindkey "^[[A" up-line-or-beginning-search
      bindkey "^[[B" down-line-or-beginning-search

      # extra variables
      export DISABLE_UNTRACKED_FILES_DIRTY="true"
      export GPG_TTY=$(tty)

      # fortune
      if [[ $- == *i* ]]; then
        fortune -s | cowsay -f www | lolcat
        task todo
      fi

      # user-defined overrides
      if [ -d "$HOME/.config/zsh/config.d" ]; then
        for file in "$HOME/.config/zsh/config.d/"*; do
          [ -f "$file" ] && source "$file"
        done
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
