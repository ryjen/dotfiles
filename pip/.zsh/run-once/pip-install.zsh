
function install_python3_packages() {

  python3_packages=(
    jrnl
    pyls
  )

  not_installed=()

  for pkg in $python3_packages; do
    python3 -c "'import $pkg'" 2>&1 >/dev/null
    if [ $? -ne 0 ]; then
      not_installed+=($pkg)
    fi
  done

  if [ ${#not_installed[@]} -gt 0 ]; then
    pip3 install ${not_installed[@]}

    if [ $? -ne 0 ]; then
      exit 1
    fi
  fi
}

function install_python2_packages() {

  python2_packages=()

  not_installed=()

  for pkg in $python2_packages; do
    python2 -c "'import $pkg'" 2>&1 >/dev/null
    if [ $? -ne 0 ]; then
      not_installed+=($pkg)
    fi
  done

  if [ ${#not_installed[@]} -gt 0 ]; then
    pip2 install ${not_installed[@]}

    if [ $? -ne 0 ]; then
      exit 1
    fi
  fi
}

type python3 2>&1 >/dev/null

if [ $? -eq 0 ]; then
  install_python3_packages
fi

type python2 2>&1 >/dev/null

if [ $? -eq 0 ]; then
  install_python2_packages
fi

