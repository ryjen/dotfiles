ASDF_DIR="${HOME}/.local/src/vendor/asdf"
ASDF_VERSION="v0.8.1"

if [ $? -ne 0 ]; then
  brew install asdf
fi

asdf install