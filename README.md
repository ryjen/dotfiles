# dotfiles

for a perfect yellow submarine with a periscope and radar.

![Yellow Submarine](https://i.ibb.co/9HGncjF/yellow-sub.jpg)

## Requirements

[Ansible](https://docs.ansible.com/ansible/latest/index.html) on a local or remote machine.

## Usage

Install on local machine `./bootstrap.sh install`
Uninstall on local machine `./bootstrap.sh uninstall`

## What's included?

See documentation for [individual roles](collections/ansible_collections/ryjen/dotfiles/roles) of programs and configurations.

Roles are divided into categories:

- **basic**: minimum install
- **default**: a few bells and whistles
- **extra**: the full shebang

Roles can be specified on the command line:

`./bootstrap.sh install -t <role>`

## Testing

`vagrant up`

or `./bootstrap.sh --test <install|uninstall>`

## Deployment

Define your inventory in `inventory/deploy/hosts` and run:

`./bootstrap.sh --deploy <install|uninstall>`
