#!/usr/bin/env bash

HOSTS="inventory/hosts"

TAGS=""
while [[ $# -gt 0 ]]; do
	case "$1" in
	--deploy)
		HOSTS="inventory/deploy/hosts"
		;;
	--test)
		HOSTS="inventory/test/hosts"
		;;
	uninstall | install)
		CMD=$1
		;;
	*)
		if [ -d "./roles/$1" ]; then
			TAGS="${TAGS},$1"
		else
			break
		fi
		;;
	esac
	shift
done

ARGS=()
if [ -n "$TAGS" ]; then
	ARGS+=(-t "${TAGS:1}" "$@")
else
	ARGS=("$@")
fi

case "$CMD" in
install | uninstall)
	ansible-playbook -i "$HOSTS" "$CMD".yml "${ARGS[@]}"
	;;
*)
	PROG=$(basename "$0")
	echo "Syntax: $PROG [options] <command> [ansible-options]"
	echo ""
	echo "  Options:"
	echo "    --deploy   :  use deploy inventory"
	echo "    --test     :  use test inventory"
	echo ""
	echo "  Commands:"
	echo "    install    :  install dotfiles"
	echo "    uninstall  :  uninstall dotfiles"
	echo ""
	echo "  Example: '$PROG install neovim' or $PROG uninstall -vv"
	echo ""
	;;
esac
