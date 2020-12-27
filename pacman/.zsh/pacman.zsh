
packages=(
  bat
  aerc
  byobu
  cowfortune
  cowsay
  docker
  docker-compose
  fzf
  git
  jq
  jrnl
  make
  neovim
  yarn
  yay
  pinentry
  ranger
  stow
  tmux
  xclip
  zsh
  yubico-pam
  yubikey-manager
)

# check all installed
# TODO: do this only once and unlink
pacman -Q ${packages[@]} 2>&1 >/dev/null

if [ $? -ne 0 ]; then
  echo "Installing system packages"
  sudo pacman -S ${packages[@]}

  if [ $? -ne 0 ]; then
    exit 1
  fi
fi

rm -f ${(%):-%N}

