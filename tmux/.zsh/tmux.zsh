export DISABLE_AUTO_TITLE='true'


## install plugin manager if needed
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
  return
fi

if ! type git > /dev/null; then
  return
fi

test_network

if [[ $? != 0 ]]; then
  return
fi

git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm


