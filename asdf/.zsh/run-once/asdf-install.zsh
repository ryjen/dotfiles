
type_exists asdf

if [ $? -ne 0 ]; then
  brew install asdf
fi

asdf install
