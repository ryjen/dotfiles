export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--layout reverse --info inline --border --preview 'bat --style=numbers --color=always --line-range :500 {} 2>/dev/null'"
