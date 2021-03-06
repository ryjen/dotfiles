ASDF_DIR="${HOME}/.local/src/vendor/asdf"
ASDF_VERSION="v0.8.1"

type git 2>&1 >/dev/null

[ $? -eq 0 ] || exit 0

git clone https://github.com/asdf-vm/asdf.git $ASDF_DIR --branch $ASDF_VERSION

source $ASDF_DIR/asdf.sh

asdf install
