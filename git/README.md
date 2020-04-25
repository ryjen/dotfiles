## [`git`](https://git-scm.com/)

> Git commands are sometimes weird, and I use my shell history/auto-completions abundantly to circumvent that rather than using a porcelain layer over git.

    ├── .config
    │   └── git
    │       └── user
    ├── .gitconfig
    ├── .gitignore
    └── bin
      ├── git-reset-author
      ├── git-remove-submodule
      └── git-sub-push

`.gitconfig` includes an external `~/.config/git/user`, allowing to have settings (credentials come to mind) specifics to each machine, cf [`.config/git/user.example`](https://github.com/Kraymer/F-dotfiles/blob/master/git/.config/git/user.example).

`icdiff`<<https://github.com/jeffkaufman/icdiff>>
