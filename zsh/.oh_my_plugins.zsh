zstyle :omz:plugins:keychain agents gpg,ssh
zstyle :omz:plugins:keychain options --quiet
zstyle :omz:plugins:ssh-agent agent-forwarding on

ZSH_THEME_GIT_PROMPT_CACHE=1

plugins=(ssh-agent last-working-dir taskwarrior autojump command-not-found colored-man-pages docker gpg-agent gnu-utils emoji sudo yarn react-native ansible colemak git-extras git-flow git-prompt extract encode64 gitignore golang keychain fzf-tab)

