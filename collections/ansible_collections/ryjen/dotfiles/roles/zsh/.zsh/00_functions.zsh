
# Reset prompt every minute to update hour
function TRAPALRM() {  # don't clear completion items on reset prompt
    if [ "$WIDGET" != "complete-word" ]; then
        zle reset-prompt
    fi
}

function change-theme() {
  $HOME/.zsh/change-theme.bash $@
}

function light-theme() {
  change-theme 65
}

function dark-theme() {
  change-theme 64
}

function connected() {
  type nc 2>&1 >/dev/null
  if [ $? -ne 0 ]; then
    return 1
  fi
  timeout 1 nc -z 1.1.1.1 53 2>&1 >/dev/null
  return $?
}

function type_exists() {
  type $@ 2>&1 >/dev/null;
  return $?
}

function checktor() {
  curl --socks5 localhost:9050 --socks5-hostname localhost:9050 -s https://check.torproject.org/api/ip
  if [ $? -ne 0 ]; then
    echo "Not running"
  fi
}
