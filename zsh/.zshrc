
type byobu-tmux >/dev/null 2>&1

if [[ $? -eq 0 ]] && [ -z "$TMUX" ]; then 
  exec byobu-tmux
fi

source ~/.oh_my.zsh

# load zsh config files
config_files=(~/.zsh/**/*.zsh(N))
for file in ${config_files}
do
  source $file
done


