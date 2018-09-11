

if [ -d "$HOME/.tmux/plugins/tpm" ]; then
  return
fi

if ! type git > /dev/null; then
  return
fi

if test_network; then
  return
fi

git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm

export DISABLE_AUTO_TITLE='true'

