# dotfiles

dotfiles for a perfect yellow submarine with a periscope and radar.

## requirements

Expects [ZSH](https://zsh.org) as the default user shell (`chsh $(which zsh)`).

Uses [GNU Stow](https://www.gnu.org/software/stow/) for creating symlinks to the home directory.

And [GNU Make](https://www.gnu.org/software/make/) for simple setup tasks.

## Why?

#### Why maintain dotfile configurations?

Portabile and consistent work environments between different systems, virtual machines and containers.

Save time setting up system packages and configurations.

#### Why change the default user shell?

Besides personal preference for functionality

by keeping the system default shell (typically BASH) and using a different user shell (ZSH)

you can potentially avoid loading user dotfiles configuration running a system script

while still maintaining the current environment variables.

## Principles

1. `main` branch for shared configuration
2. sub branches for OS or Package Manager configurations (see `macos`, `linux` or `pacman`) kept in sync with merges
4. stow ignore and git ignore to manage meta files
5. make build system to perform initial setup and module installations
3. `minimal`, `basic` and `extra` easy install groups
4. Simple: run `make install` and good to go

## Known issues

* neovim 0.5.0 lua configuration requires some manual restarting or config

## TODO

* debian/ubuntu based branch
* lightweight branch for containers

## Ideas

* possibly a branch per package, with main,system,user integration branches. This could keep the disk space of the repo
to a minimum with sparse clones and remote merges.
  1. workflow would be to create a branch for your needs `ubuntu-container`
  2. merge packages you need `git merge installer; git merge stow; git merge apt; git merge zsh`
  3. install/stow `make install` or `stow apt`
* allow insert current env variables into some stowed files:
  1. setup install location for modules `mkdir -p .install/module`
  2. ignore install location in repository `echo ".install" >> .gitignore`
  3. create module files from current environment `cat module/file | envsubst > .install/module/file`
  4. use the install location for symlinks `stow -D .install module`
* possibly integrate or copy from [spacevim](https://spacevim.org/)
