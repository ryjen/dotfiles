# dotfiles

for a perfect yellow submarine with a periscope and radar.

![Yellow Submarine](https://i.ibb.co/9HGncjF/yellow-sub.jpg)

## Design

1. A folder to contain the source of truth ($HOME/.local/share/dotfiles)
2. System installer for packages, templating, customizations, secrets, and other tasks (ansible)
3. GNU Stow to link the source of truth to appropriate locations
4. Categorize the installation for use cases
5. Best effort to support uninstalling
6. Leverages reuse


### Installation

Several events may occur during installation:

1. Will use system packages when it can (homebrew, apt, pacman, winget, etc).
2. Will prompt for secrets in a vault to configure when needed (gpg).
3. Leverages variables and templating for customizations. 
4. Defaults to local, supports remote configurations.

### Uninstallation

Best efforts are made to support uninstallation by design.

1. Reverses package installs
2. Unlinks configurations from source of truth

## Requirements

Python and [Ansible](https://docs.ansible.com/ansible/latest/index.html) on a local or remote machine.

### Windows 

Windows users must use WSL for ansible.  From there you can target the Windows host with WinRM

## Usage

The bootstrap script attempts to simplify the commands.

Install on local machine `./bootstrap.sh install`
Uninstall on local machine `./bootstrap.sh uninstall`

## What's included?

See documentation for [individual roles](collections/ansible_collections/ryjen/dotfiles/roles) of programs and configurations.

Roles are divided into categories via tags:

- **basic**: minimum install
- **default**: a few more bells and whistles
- **extra**: the full shebang

`./bootstrap.sh install -t '<basic|default|extra>'`

Individual roles are also tags and can be specified on the command line:

`./bootstrap.sh install -t <role>`

## Testing

`vagrant up`

or `./bootstrap.sh --test <install|uninstall>`

## Deployment

Define your inventory in `inventory/deploy/hosts` and run:

`./bootstrap.sh --deploy <install|uninstall>`

