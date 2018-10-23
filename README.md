These dotfiles are forked from *F-dotfiles* which is an opiniated dotfiles organization scheme based on stow.

Highest priorities are ease of maintenance and deployment on both Linux and OS X.*

- **`stow` powered:** symlink dotfiles and thus keep them always up-to-date in your repository
- **topical organization:** organize dotfiles by application facilitating reuse across different machines
- **clever naming scheme:** the repository architecture is easy to browse while staying compatible with `stow` symlinking mechanism
- **KISS:** there is deliberately no build script involved at all, the repository consist of dotfiles all installable using same modus operandi (`stow <directory>`)
- **documentation:** each package has a *README.md* which present its purpose and a flat `tree` view of its files. Install notes and requirements can also be listed. 

## Install

1. clone the repository : `git clone https://github.com/ryjen/dotfiles ~/ ; cd ~/dotfiles`
1. setup `stow`, *inception style* : `stow -t ~ @home` or `stow -t ~ @work` or an environment of your creation 
1. install desired package via `stow <directory>` <sup id="a1">[1](#f1)</sup>

When needed, special install instructions are present in package `README.md` file.

## Rules

> *Walter -* The rules really tie the repo together, do they not?  

### Directories naming

- lowercase for packages to install in `$HOME` (the default)
- titlecase for packages to install as root in `/`, eg
  [`@Daemon-osx`](https://github.com/ryjen/dotfiles/blob/master/attic/@Daemon-osx)
- leading `@` for environment packages and subpackages, eg
  [`@mac`](https://github.com/ryjen/dotfiles/blob/master/%40mac/), [`attic/@Daemon-osx`](https://github.com/ryjen/dotfiles/blob/master/attic/@Daemon-osx)
- leading `_` for non packages, eg [`_homebrew`](https://github.com/ryjen/dotfiles/blob/master/_homebrew) meaning that these directories must not be *stowed*

Having a convention for subpackage naming enable us to write a [`.stow-global-ignore`](https://github.com/ryjen/dotfiles/blob/master/stow/.stow-global-ignore#L7) file so that subpackages are not symlinked when stowing parent package. 

Each package has a `README.md` which present its purpose and a flat `tree` view of its files.
Install notes and requirements can also be listed.

### Ignore files <sup><sub>[[cf example]](https://github.com/Kraymer/F-dotfiles/blob/master/_sublime_text_3/.gitignore)</sub></sup>

Quoting stow [documentation](https://www.gnu.org/software/stow/manual/html_node/Installing-Packages.html#Installing-Packages) :

> if Stow can create a single symlink that points to an entire subtree within the package tree, it will choose to do that rather than create a directory in the target tree and populate it with symlinks.

`.gitignore` can be present in packages because of this behaviour, in order to avoid having your repository cluttered with unknown files. 
 
### Secret files <sup><sub>[[cf example]](https://github.com/Kraymer/F-dotfiles/blob/master/git/.config/git/credentials.local)
See [example](https://github.com/ryjen/dotfiles/blob/master/%40macos/.config/.gitconfig.sec.example).

Files that contain sensitive information and should not be published are kept secret using package specific `.gitignore` files.  
These files are prominently listed in the package `README.md` with a ✏ symbol aside.  
Because the secret file itself is not tracked, a template is commited instead having same name but with the `.local` suffix appended. This template is intended to serve as a base for edition and can be renamed (removing the suffix) after its content is edited.

### Multi-platforms paths <sup><sub>[[cf example]](https://github.com/Kraymer/F-dotfiles/blob/master/_sublime_text_3/%40linux/.config/sublime-text-3/Packages/User)

For example, let's say you want to store one config file as `~/.config/myapp/spam.conf` on Linux and as `~/Library/myapp/spam.conf` on macOS.  

Put the shared part of filepaths in a shared `_common` folder : `myapp/_common/myapp/spam.conf`  
Then, create one subpackage per OS to host each specific directories structure and use symlink to bridge to `_common` files :  
`myapp/@linux/.config -> ../ _common/myapp/`  
`myapp/@macOS/Library -> ../ _common/myapp/`

Feel confused ? Check [example](https://github.com/ryjen/dotfiles/tree/master/sublime_text_3/%40linux/.config/sublime-text-3)

---
<i id="f1">1</i> it's because we installed `stow` package at step 2 that the flag `-t ~` can be omitted here, see [.stowrc](https://github.com/ryjen/dotfiles/blob/master/stow/.stowrc) [⤸](#a1)  
<i id="f2">2</i> https://www.youtube.com/watch?v=ezQLP1dj_t8 [⤸](#a2)
