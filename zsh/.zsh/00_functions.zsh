
# Reset prompt every minute to update hour
function TRAPALRM() {  # don't clear completion items on reset prompt
    if [ "$WIDGET" != "complete-word" ]; then
        zle reset-prompt
    fi
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

