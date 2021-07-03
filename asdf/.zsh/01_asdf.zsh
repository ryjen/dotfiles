ASDF_DIR="${HOME}/.local/src/vendor/asdf"

[ -d ${ASDF_DIR} ] || exit 0

source $ASDF_DIR/asdf.sh

fpath=(${ASDF_DIR}/completions $fpath)

