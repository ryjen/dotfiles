# dotfiles

dotfiles for a perfect yellow submarine with a periscope and radar.

## requirements

Expects [ZSH](https://zsh.org) as the default user shell (`chsh $(which zsh)`).

Requires [GNU Stow](https://www.gnu.org/software/stow/) for creating symlinks to the home directory.

Optionally, [GNU Make](https://www.gnu.org/software/make/) for simple setup tasks.

## Why?

#### Why maintain dotfile configurations?

Portable and consistent work environments between different systems, virtual machines and containers.

Save time setting up system packages and configurations.

#### Why change the default user shell?

Keeping the system default shell (typically BASH) and using a different user shell (ZSH)

You can avoid loading user dotfiles configuration running a system script while still maintaining the current environment variables.

## Principles

1. `main` branch for shared configuration
2. sub branches for OS or Package Manager configurations (see `macos`, `linux` or `pacman`) kept in sync with merges
3. stow ignore and git ignore to manage meta files
4. minimal requirements (zsh and stow)
5. install groups - `minimal`, `basic` and `extra` 

## Known issues

* neovim 0.5.0 lua configuration requires some manual restarting or config (run `:PackerInstall`)
* user security values need manual configuration

## TODO

* debian/ubuntu based branch
* lightweight branch for containers
* prompt for secure values

## Ideas

* possibly a branch per package, with integration branches for systems and users. 
  1. workflow would be to create a branch for your needs `ubuntu-container`
  2. merge packages you need `git merge stow; git merge apt; git merge zsh`
  3. customize
* allow inserting current env variables into some stowed files. Setup example:
  1. setup install location for modules `mkdir -p .install/module`
  2. ignore install location in repository `echo ".install" >> .gitignore`
  3. create module files from current environment `cat module/file | envsubst > .install/module/file`
  4. use the install location for symlinks `stow -D .install module`
* possibly integrate or copy from [spacevim](https://spacevim.org/)
* prompt for secure variables:
  1. additional setup script to prompt user for values to replace in ``*.example` files
