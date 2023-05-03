#!/usr/bin/env bash

case "$1" in
test)
	shift
	ansible-playbook -i inventory/test bootstrap.yml "$@"
	;;
install)
	ansible-playbook -i inventory bootstrap.yml -t install "$@"
	;;

uninstall)
	ansible-playbook -i inventory bootstrap.yml -t uninstall "$@"
	;;
*)
	echo "Syntax: $(basename "$0") <command>"
	echo ""
	echo "  test    : test installation in vagrant machine"
	echo "  install : install on current local machine"
	echo "  uninstall : uninstall on current local machine"
	echo ""
	;;
esac
