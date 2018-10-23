## [`git`](https://git-scm.com/)

> Git commands are sometimes weird, and I use my shell history/auto-completions abundantly to circumvent that rather than using a porcelain layer over git.

    ├── .config
    │   └── git
    │       └── gitconfig.sec
    ├── .gitconfig
    ├── .gitignore
    └── bin
      ├── git-reset-author
      └── git-sub-push

`.gitconfig` includes an external `~/.config/.gitconfig.sec`, allowing to have settings (credentials come to mind) specifics to each machine, cf [`@mac/.config/.gitconfig.sec.example`](https://github.com/Kraymer/F-dotfiles/blob/master/%40mac/.config/.gitconfig.sec.example).

`icdiff`<<https://github.com/jeffkaufman/icdiff>>  
