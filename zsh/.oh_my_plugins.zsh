
export ZSH_TMUX_AUTOSTART='true'

zstyle :omz:plugins:ssh-agent agent-forwarding on
zstyle :omz:plugins:ssh-agent identities id_home id_work

plugins=(tmux ssh-agent last-working-dir taskwarrior autojump command-not-found adb colored-man-pages docker gpg-agent gnu-utils zsh-autosuggestions zsh-syntax-highlighting battery emoji sudo)


