# dotfiles

for a perfect yellow submarine with a periscope and radar.

## requirements

[Ansible](https://docs.ansible.com/ansible/latest/index.html) on a local or remote machine.

## What's included?

See documentation for [individual roles](collections/ansible_collections/ryjen/dotfiles/roles).

## Testing

`vagrant up`

`ansible-playbook -i inventory/test/hosts bootstrap.yml`

## Deployment

To localhost:

`ansible-playbook bootstrap.yml`

To a defined host in inventory:

`ansible-playbook -i inventory/server/hosts bootstrap.yml`
