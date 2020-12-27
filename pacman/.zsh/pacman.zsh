
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
pacman -Qs ${packages[@]} 2>&1 >/dev/null

if [ $? -ne 0 ]; then
  echo "Installing system packages"
  sudo pacman -S ${packages[@]}

  if [ $? -eq 0 ]; then
    rm -f ${(%):-%N}
  fi
fi


