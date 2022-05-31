ASDF_DIR="${HOME}/.local/src/vendor/asdf"
ASDF_VERSION="v0.8.0"

if [ ! -d $ASDF_DIR ]; then
  git clone https://github.com/asdf-vm/asdf.git $ASDF_DIR --branch $ASDF_VERSION
fi

source $ASDF_DIR/asdf.sh

fpath=(${ASDF_DIR}/completions $fpath)
# initialise completions with ZSH's compinit
autoload -Uz compinit
compinit

