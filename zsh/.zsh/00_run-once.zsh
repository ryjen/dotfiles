
RUN_ONCE_DIR="${HOME}/.zsh/run-once"

[ -d ${RUN_ONCE_DIR} ] || exit 0

for s in ${RUN_ONCE_DIR}/*.zsh*; do

  local LOCK_FILE="${s:%.zsh*}.done"

  if [ ! -e ${LOCK_FILE} ]; then
    source ${s}
    touch ${LOCK_FILE}
  fi
done