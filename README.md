
# dotfiles

dotfiles for a perfect yellow submarine with a periscope and radar.

## manager

Uses [GNU Stow](https://www.gnu.org/software/stow/) for creating symlinks to the home directory.

And a [GNU Make](https://www.gnu.org/software/make/) for simple setup tasks.

## principles

 1. `main` branch for shared configuration
 2. sub branches for OS or Package Manager configurations
 3. minimal as possible, kept in sync
 4. stow and git ignore manage meta files

## desired

 1. insert env variables into files

