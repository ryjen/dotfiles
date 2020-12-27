export DISABLE_AUTO_TITLE='true'

function ssh() {
	/usr/bin/ssh -t "$@" tmux new-session -A -s ${USER}-session
}

function rawssh() {
  /usr/bin/ssh $@
}

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then

  type git 2>&1 >/dev/null

  if [ $? -eq 0 ]; then
    git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
  fi

fi
