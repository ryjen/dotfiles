#!/usr/bin/env bash

ansible-playbook -i inventory bootstrap.yml --ask-become-pass
