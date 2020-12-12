export DISABLE_AUTO_TITLE='true'

if [ -d "$HOME/.tmux/plugins/tpm" ]; then
  return
fi

## no plugin manager, install if able
type git >/dev/null
if [ $? -eq 0 ]; then
  git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
fi


