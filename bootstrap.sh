#!/usr/bin/env bash

case "$1" in
  test)
    shift
    ansible-playbook -i inventory/test bootstrap.yml --ask-become-pass $@
    ;;
  help)
    echo "Syntax: $(basename $0) [test | help]"
    ;;
  *) 
    ansible-playbook -i inventory bootstrap.yml --ask-become-pass $@
    ;;
esac

