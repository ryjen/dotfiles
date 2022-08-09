#!/usr/bin/env bash

CMD="$1"
shift

case "$CMD" in
  test)
    vagrant up
    ansible-playbook -i inventory/test bootstrap.yml $@
    ;;
  deploy)
    ansible-playbook -i inventory/micrantha bootstrap.yml $@
    ;;
  install)
    ansible-playbook -i inventory bootstrap.yml $@
    ;;
  *)
    echo "Syntax: $(basename $0) <command>"
    echo ""
    echo "  test    : test installation in vagrant machine"
    echo "  install : install on current local machine"
    echo ""
    ;;
esac

