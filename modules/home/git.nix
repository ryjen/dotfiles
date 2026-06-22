{
  lib,
  config,
  ...
}:
let
  micranthaEnabled = config.dotfiles.profiles.micrantha.enable;
  gitEditor =
    if config.programs.neovim.enable then
      "nvim"
    else if config.programs.helix.enable then
      "hx"
    else
      "vi";
in
{
  programs.git = {
    enable = true;
    ignores = [
      "*~"
      "*.bak"
      "*.log"
      "**/.claude/settings.local.json"
    ];
    includes = [
      {
        path = "~/.config/git/local.config";
      }
    ]
    ++ lib.optionals config.dotfiles.profiles.micrantha.enable [
      {
        condition = "gitdir:~/**/micrantha/**";
        path = "~/.config/git/conf.d/micrantha";
      }
    ];
    aliases = {
      ff = "flow feature";
      wip = "!git add --all; git ci -m WIP";
      co = "checkout";
      blame = "blame -w -C -C -C";
      wdiff = "diff --word-diff";
      cob = "checkout -b";
      last = "log -1 HEAD";
      lbr = "for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads/ | head -n 1";
      st = "status";
      fpush = "push --force-with-lease";
      stash = "stash --all";
      save = "commit -a";
      aliases = "config --get-regex alias";
      loga = "log --pretty=format:'%C(yellow)%h %<(24)%C(red)%ad %<(18)%C(green)%an %C(reset)%s' --date=local --max-count=10";
      lg = "log --graph --abbrev-commit --decorate --date=relative --all";
      changelog = "log origin..HEAD --format='* %s%n%w(,4,4)%+b'";
      glg = "log --oneline --decorate --all --graph";
      undo = "reset HEAD~1 --mixed";
      correct = "reset --hard";
      uncommit = "reset --soft HEAD~";
      done = "push origin HEAD";
      unstage = "reset HEAD --";
      del = "branch -D";
      br = "branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate";
      cleanup-merged = "!f(){ git fetch && git branch --merged | grep -v '* ' | xargs git branch --delete; };f";
      amend = "commit --amend --reuse-message=HEAD";
      fixup = "rebase -i HEAD~2";
    };
    extraConfig = {
      core.excludesfile = "~/.gitignore";
      difftool.prompt = false;
      gui.gcwarning = false;
      help.autocorrect = 1;
      mergetool = {
        keepBackup = false;
        prompt = false;
      };
      pull.rebase = true;
      push.default = "simple";
      rebase.autoStash = true;
      user.useConfigOnly = true;
      init = {
        defaultBranch = "main";
        templateDir = "~/.config/git/project";
      };
      filter.lfs = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };
      sendemail.annotate = "yes";
      rerere = {
        enabled = true;
        autoUpdate = true;
      };
      branch.sort = "-committerdate";
      column.ui = "auto";
      commit.template = "~/.config/git/commit-message";
      core.editor = gitEditor;
      merge = {
        tool = "vimdiff";
        conflictstyle = "diff3";
      };
      pager = {
        diff = "bat -p";
        show = "bat -p";
      };
      core.pager = "bat -p";
      credential.helper = "!pass-git-helper $@";
      sequence.editor = gitEditor;
    }
    // lib.optionalAttrs micranthaEnabled {
      url."git+ssh://git@gitlab.com/micrantha" = {
        insteadOf = [
          "https://micrantha.com"
          "git+ssh://git@micrantha.com"
          "https://git.micrantha.com"
          "git+ssh://git@git.micrantha.com"
        ];
      };
    };
  };

  home.file.".gitignore".source = ../../files/home/.gitignore;
  xdg.configFile."git/local.config".text = ''
    # Local Git configuration.
    #
    # Ownership:
    # - machine-specific
    # - writable by the user
    # - never automatically promoted by configctl
  '';
  xdg.configFile."git/commit-message".source = ../../files/home/.config/git/commit-message;
  xdg.configFile."git/project/hooks" = {
    source = ../../files/home/.local/share/git/hooks;
    recursive = true;
  };
}
