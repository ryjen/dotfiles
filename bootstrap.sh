#!/usr/bin/env bash

CMD=$1
shift

case "$CMD" in
test)
	ansible-playbook -i inventory/test/hosts install.yml "$@"
	;;
init)
	ansible-playbook -i inventory/hosts install.yml --ask-vault-pass -t basic "$@"
	;;
*)
	ansible-playbook -i inventory/hosts $CMD.yml "$@"
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
