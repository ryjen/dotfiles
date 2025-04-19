#!/usr/bin/env bash

HOSTS="inventory/hosts"
ARGS=()
TAGS=""

if ! which ansible >/dev/null ; then 
   echo "Install ansible first"
   exit 1
fi

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

if [ -n "$TAGS" ]; then
	ARGS+=(-t "${TAGS:1}" "$@")
else
	ARGS=("$@")
fi

if ! ./.bin/ansible-vault-pass >/dev/null; then
  ARGS+=(--ask-vault-pass)
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
