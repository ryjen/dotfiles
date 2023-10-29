export TMOUT=60  # refresh prompt every minute (thus updating PS1 'hour' component)

# Completion system
_comp_options+=(globdots)	# auto-complete dot files

export LC_ALL="en_CA.UTF-8"

# History
export HISTFILE=~/.zsh_history
export HISTSIZE=100000
export HIST_STAMPS="mm/dd/yyyy"
export SAVEHIST=100000
setopt EXTENDED_HISTORY # add timestamps to history
setopt SHARE_HISTORY    # share history between sessions ???
setopt APPEND_HISTORY   # adds history

# set various options
setopt AUTO_CD
setopt EXTENDED_GLOB
setopt HIST_IGNORE_ALL_DUPS  # don't record dupes in history
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY SHARE_HISTORY  # adds history incrementally and share it across sessions
setopt NO_BG_NICE       # don't nice background tasks
setopt NO_CASE_GLOB     # Case insensitive globbing
setopt NO_LIST_BEEP

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search # Up
bindkey "^[[B" down-line-or-beginning-search # Down

export DISABLE_UNTRACKED_FILES_DIRTY="true" # makes repository status check for large repositories much faster
