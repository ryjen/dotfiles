# dotfiles

for a perfect yellow submarine with a periscope and radar.

## Requirements

[Ansible](https://docs.ansible.com/ansible/latest/index.html) on a local or remote machine.

## What's included?

See documentation for [individual roles](collections/ansible_collections/ryjen/dotfiles/roles).

## Usage

Install on local machine `./bootstrap.sh install`
Uninstall on local machine `./bootstrap.sh uninstall`

## Testing

`vagrant up`

`ansible-playbook -i inventory/test/hosts bootstrap.yml`

or `./bootstrap.sh test -t <install|uninstall>`

## Deployment

Define your inventory (example: inventory/server/hosts) and run:

`ansible-playbook -i inventory/server/hosts bootstrap.yml`
