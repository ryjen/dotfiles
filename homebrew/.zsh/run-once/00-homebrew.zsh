/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew_packages=(
  ansible
  aquasecurity/trivy/trivy # docker security
  asdf # version manager
  autojump
  aws-keychain
  awscli
  bat # better pager
  byobu # better tmux
  certbot
  cheat
  clang-format
  cmake
  cocoapods
  composer
  conan
  consul
  cowsay
  ctags
  ctop
  curl
  delta # differ
  devd
  diction
  direnv
  dnsmasq
  dos2unix
  ffmpeg
  fortune
  fzf
  git-flow
  git-lfs
  git-secrets
  glances
  glow
  gnu-typist
  gnuplot
  htop
  hugo
  imagemagick
  jq
  jrnl
  keychain
  launchctl-completion
  less
  libarchive
  libwebsockets
  lolcat
  maven
  mitmproxy
  mkcert
  modd
  mosh
  ncdu
  neomutt
  neovim
  ninja
  nmap
  nss
  pam_yubico
  pandoc
  pass
  podman
  postgresql
  rename
  smartmontools
  sqlcipher
  stow
  syncthing
  task
  telnet
  timewarrior
  toilet
  trash
  weechat
  yarn
  yq
  yubico-piv-tool
  zsh
  zsh-autosuggestions
  zsh-autocompletions
)

brew install ${brew_packages[@]}

