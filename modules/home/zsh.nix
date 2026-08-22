{
  config,
  lib,
  pkgs,
  ...
}:
let
  machineProfile = config.dotfiles.host.name;
  machineProfileName = if machineProfile == null then "unconfigured" else machineProfile;
  zshPromotedProfilesRoot = ../../files/home/.config/zsh/config.d;
  zshPromotedProfile = zshPromotedProfilesRoot + "/${machineProfileName}";
  hasZshPromotedProfile = machineProfile != null && builtins.pathExists zshPromotedProfile;
in
{
  xdg.configFile = lib.mkIf hasZshPromotedProfile {
    "zsh/config.d/${machineProfileName}" = {
      source = zshPromotedProfile;
      recursive = true;
    };
  };

  home.file.".zshenv".text = ''
    export ZDOTDIR="${config.xdg.configHome}/zsh"
  '';

  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

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
      unsetopt extended_glob
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
      zmodload zsh/terminfo

      # Prefix-aware history navigation. Bind both common cursor encodings plus
      # the terminal-advertised sequence so arrows work in normal/application mode.
      for key in "^[[A" "^[OA" "''${terminfo[kcuu1]}"; do
        [[ -n "$key" ]] && bindkey "$key" up-line-or-beginning-search
      done
      for key in "^[[B" "^[OB" "''${terminfo[kcud1]}"; do
        [[ -n "$key" ]] && bindkey "$key" down-line-or-beginning-search
      done

      # extra variables
      export GPG_TTY=$(tty)

      # fortune
      if [[ $- == *i* ]]; then
        fortune -s | cowsay -f www | lolcat
        task todo
      fi

      # Reviewed profile-scoped fragments promoted into dotfiles. Home Manager
      # materializes this namespace without taking ownership of root config.d.
      if [ -d "$HOME/.config/zsh/config.d/${machineProfileName}" ]; then
        for file in "$HOME/.config/zsh/config.d/${machineProfileName}/"*; do
          [ -f "$file" ] && source "$file"
        done
      fi

      # Live user-authored promotion candidates override reviewed fragments.
      if [ -d "$HOME/.config/zsh/config.d" ]; then
        for file in "$HOME/.config/zsh/config.d/"*; do
          [ -f "$file" ] && source "$file"
        done
      fi

      # Machine-local overrides remain unmanaged and have highest precedence.
      [ -f "$HOME/.config/zsh/local.zsh" ] && source "$HOME/.config/zsh/local.zsh"
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
