#!/usr/bin/env bash

CMD=$1
shift

case "$CMD" in
test)
	ansible-playbook -i inventory/test/hosts install.yml --ask-vault-pass "$@"
	;;
init)
	ansible-playbook -i inventory/hosts install.yml --ask-vault-pass -t basic "$@"
	;;
install | uninstall)
	ansible-playbook -i inventory/hosts "$CMD".yml --ask-vault-pass "$@"
	;;
*)
	echo "Syntax: $(basename "$0") <command>"
	echo ""
	echo "  test    : test installation in vagrant machine"
	echo "  init    : install on a new system"
	echo "  <play>  : run a playbook"
	echo ""
	;;
esac
