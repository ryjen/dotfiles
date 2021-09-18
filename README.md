# dotfiles

dotfiles for a perfect yellow submarine with a periscope and radar.

## requirements

Expects [ZSH](https://zsh.org) as the default user shell (`chsh $(which zsh)`).

Uses [GNU Stow](https://www.gnu.org/software/stow/) for creating symlinks to the home directory.

And a [GNU Make](https://www.gnu.org/software/make/) for simple setup tasks.

## Why?

#### Why maintain dotfile configurations?

Portability between different systems and ensuring a consistent work environment in a terminal.

#### Why change the default user shell?

By keeping the system default shell
(typically BASH) and using a different user shell (ZSH)

loading dotfiles configuration is less likely to happen from a system script (unless specified by a shebang)

while maintaining the current environment variables.

## principles

1. `main` branch for shared configuration
2. sub branches for OS or Package Manager configurations (see `macos`, `linux` or `pacman`) kept in sync with merges
4. stow ignore and git ignore to manage meta files
5. make build system to perform initial setup and module installations
3. `minimal`, `basic` and `extra` easy install groups
4. Simple: run `make install` and good to go

## Known issues

* neovim 0.5.0 lua configuration requires some manual restarting or config 

## TODO

* debian based branch
* allow insert env variables into stowed files:
  1. setup install location for modules `mkdir -p .install/module`
  2. ignore install location in repository `echo ".install" >> .gitignore`
  3. create module files from current environment `cat module/file | envsubst > .install/module/file`
  4. use the install location for symlinks `stow -D .install module`
* possibly integrate or copy from [spacevim](https://spacevim.org/)
