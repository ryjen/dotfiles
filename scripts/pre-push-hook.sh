#!/usr/bin/env bash
# Custom pre-push hook — runs WIP, tag, and submodule checks,
# then delegates to pre-commit's pre-push stage if available.

set -o nounset

zero=$(git hash-object --stdin </dev/null | tr '[0-9a-f]' '0')
status=0

check_wip() {
  while read -r local_ref local_oid remote_ref remote_oid; do
    if [ "$local_oid" = "$zero" ]; then
      continue
    fi

    if [ "$remote_oid" = "$zero" ]; then
      range="$local_oid"
    else
      range="$remote_oid..$local_oid"
    fi

    commit=$(git rev-list -n 1 --grep '^WIP' "$range" 2>/dev/null)
    if [ -n "$commit" ]; then
      echo "ERROR [pre-push]: WIP commit found in $local_ref, push blocked." >&2
      status=1
    fi
  done
}

check_tags() {
  while read -r local_ref local_oid remote_ref remote_oid; do
    case "$local_ref" in
      refs/tags/*)
        if [ "$remote_oid" != "$zero" ]; then
          echo "ERROR [pre-push]: tag $local_ref already exists on remote, modify/delete blocked." >&2
          status=1
          continue
        fi
        obj_type=$(git cat-file -t "$local_oid" 2>/dev/null)
        if [ "$obj_type" = "commit" ]; then
          echo "ERROR [pre-push]: unannotated tag ${local_ref#refs/tags/}. Use 'git tag -a' instead." >&2
          status=1
        fi
        ;;
    esac
  done
}

check_submodules() {
  if [ ! -f .gitmodules ]; then
    return 0
  fi

  while IFS= read -r line; do
    case "$line" in
      -*)
        echo "ERROR [pre-push]: uninitialized submodule: ${line#?}" >&2
        status=1
        ;;
      +*)
        echo "ERROR [pre-push]: submodule checkout differs from the recorded commit: ${line#?}" >&2
        status=1
        ;;
      U*)
        echo "ERROR [pre-push]: submodule has merge conflicts: ${line#?}" >&2
        status=1
        ;;
    esac
  done < <(git submodule status --recursive)
}

# Read stdin once into a temp file so each check can iterate.
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
cat >"$tmp"

# Validation hooks are read-only. Submodule publication is an explicit operator action.
check_submodules

exec <"$tmp"
check_wip

exec <"$tmp"
check_tags

# Delegate to pre-commit's pre-push stage if installed.
if command -v pre-commit &>/dev/null && [ -f .pre-commit-config.yaml ]; then
  pre-commit run --hook-stage pre-push 2>&1 | sed 's/^/  /'
  if [ ${PIPESTATUS[0]} -ne 0 ]; then
    status=1
  fi
fi

exit "$status"
