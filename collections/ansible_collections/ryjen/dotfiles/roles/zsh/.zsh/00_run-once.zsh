
RUN_ONCE_DIR="${HOME}/.zsh/run-once"

[ -d ${RUN_ONCE_DIR} ] || exit 0

function welcome() {
  echo -e "Welcome to \x1b[1;36mryjen's \x1b[1;35mdotfiles\x1b[0m...\n"

  echo -e "Installing system packages and running initial configuration.\n"

  echo "Waiting 15 seconds.  Hit ENTER to continue, or CTRL-C to cancel."

  read -t 15
}

for s in ${RUN_ONCE_DIR}/*.zsh; do

  local LOCK_FILE="${s%.zsh*}.done"

  if [ ! -e ${LOCK_FILE} ]; then

    if [ -n ${welcomed} ]; then
      welcome
      welcomed=1
    fi
    source ${s}
    touch ${LOCK_FILE}
  fi
done
