#!/usr/bin/env bash

case "$1" in
  test)
    shift
    ansible-playbook -i inventory/test bootstrap.yml --ask-become-pass $@
    ;;
  install) 
    ansible-playbook -i inventory bootstrap.yml --ask-become-pass $@
    ;;
  *)
    echo "Syntax: $(basename $0) <command>"
    echo ""
    echo "  test    : test installation in vagrant machine"
    echo "  install : install on current local machine"
    echo ""
    ;;
esac

