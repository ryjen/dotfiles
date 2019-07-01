export DISABLE_AUTO_TITLE='true'

if [ -d "$HOME/.tmux/plugins/tpm" ]; then
  return
fi

## no plugin manager, install if able
if [ command_exists git ] && [ network_connected ]; then
  git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
fi


