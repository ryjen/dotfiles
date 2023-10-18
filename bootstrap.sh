#!/usr/bin/env bash

CMD=$1
shift

ARGS="${@:-"-t basic"}"

case "$CMD" in
test)
	ansible-playbook -i inventory/test/hosts --ask-vault-pass install.yml "$ARGS"
	;;
install)
	ansible-playbook -i inventory/hosts install.yml --ask-vault-pass "${ARGS}"
	;;
uninstall)
	ansible-playbook -i inventory/hosts --ask-vault-pass $CMD.yml "$ARGS"
	;;
*)
	echo "Syntax: $(basename "$0") <command>"
	echo ""
	echo "  test      : test installation in vagrant machine"
	echo "  install   : add dotfiles to system"
	echo "  uninstall : remove dotfiles from system"
	echo ""
	;;
esac
