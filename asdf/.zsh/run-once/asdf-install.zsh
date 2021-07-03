ASDF_DIR="${HOME}/.local/src/vendor/asdf"
ASDF_VERSION="v0.8.1"

type_exists asdf

if [ $? -ne 0 ]; then
  brew install asdf
fi

asdf install
