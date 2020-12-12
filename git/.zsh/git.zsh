alias git-log-since-rlz='git log --oneline --pretty=format:"%h%x09%an%x09%s" --no-merges `git describe --abbrev=0 --tags`..HEAD'

# Print all commits that modified files matching given pattern
#   $1 filename pattern
function git_commits_on_files() {
    for REV in `git rev-list master --abbrev-commit`
    do
      FILEPATH=`git diff-tree --no-commit-id --name-only --abbrev -r $REV | grep $1`
      echo "$REV $FILEPATH" | grep $1
    done
}

function git_filesize() {
  git log $1 | grep "^commit" | cut -f2 -d" " | while read hash; do
     echo -n "$hash -- "
     git show $hash:$1 | wc -c
  done
}

function git_prompt_info() {
  ref=$(git symbolic-ref HEAD 2> /dev/null) || return
  echo "$ZSH_THEME_GIT_PROMPT_PREFIX${ref#refs/heads/}${ZSH_THEME_GIT_PROMPT_SUFFIX}"
}
