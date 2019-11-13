type byobu-tmux >/dev/null 2>&1

if [[ $? -eq 0 ]] && [ -z "$TMUX" ]; then
  exec byobu-tmux
fi

# start tmux if necessary
if [ -z "$TMUX" ] && test type tmux 2>&1 /dev/null; then
  [[ ! $TERM =~ screen ]] && [ -z $TMUX ] && exec tmux
fi

source ~/.oh_my.zsh

# load zsh config files
config_files=(~/.zsh/**/*.zsh(N))
for file in ${config_files}
do
  source $file
done

