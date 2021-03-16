export DISABLE_AUTO_TITLE='true'

function shmux() {
  local options
  if [ -n $BYOBU_TTY ] && [ $BYOBU_BACKEND = "tmux" ]; then
    options="set -g status off"
  fi
	/usr/bin/ssh -t "$@" tmux new-session -x - -y - -A -s ${USER}-session; $options
}

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then

  type git 2>&1 >/dev/null

  if [ $? -eq 0 ]; then
    git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
  fi

fi
