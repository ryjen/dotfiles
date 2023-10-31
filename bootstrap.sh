#!/usr/bin/env bash


HOSTS="inventory/hosts"

while :; do
  CMD=$1
  shift
  case "$CMD" in
  --deploy | -d)
	  HOSTS="inventory/deploy/hosts"
	  ;;
  --test | -t)
	  HOSTS="inventory/test/hosts"
	  ;;
  --password | -p)
	  ARGS="--ask-vault-password"
	  ;;
    *)
      break
      ;;
    esac
done

case "$CMD" in
install | uninstall)
	ansible-playbook -i "$HOSTS" "$CMD".yml "$ARGS" "$@"
	;;
*)
	echo "Syntax: $(basename "$0") [options] <command>"
	echo ""
	echo "  Options:"
	echo "    --deploy   :  use deploy inventory"
	echo "    --test     :  use test inventory"
	echo "    --password :  ask vault password"
	echo ""
	echo "  Commands:"
	echo "    install    :  install dotfiles"
	echo "    uninstall  :  uninstall dotfiles"
	echo ""
	;;
esac
