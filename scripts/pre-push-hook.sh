#!/usr/bin/env bash
# Custom pre-push hook — runs WIP, tag, and submodule checks,
# then delegates to pre-commit's pre-push stage if available.

set -o nounset

remote="$1"
url="$2"
zero=$(git hash-object --stdin </dev/null | tr '[0-9a-f]' '0')
status=0

check_wip() {
  while read local_ref local_oid remote_ref remote_oid; do
    if [ "$local_oid" = "$zero" ]; then continue; fi

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
  while read local_ref local_oid remote_ref remote_oid; do
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

sync_submodules() {
  if [ ! -f .gitmodules ]; then return 0; fi
  echo "INFO [pre-push]: pushing submodule changes first..."
  git submodule foreach 'git push' 2>&1 | sed 's/^/  /'
  if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "ERROR [pre-push]: submodule push failed." >&2
    status=1
  fi
}

# Read stdin once into a temp file so each check can iterate.
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
cat > "$tmp"

# Run checks (each reads from the temp file)
sync_submodules

exec < "$tmp"
check_wip

exec < "$tmp"
check_tags

# Delegate to pre-commit's pre-push stage if installed
if command -v pre-commit &>/dev/null && [ -f .pre-commit-config.yaml ]; then
  pre-commit run --hook-stage pre-push 2>&1 | sed 's/^/  /'
  if [ ${PIPESTATUS[0]} -ne 0 ]; then
    status=1
  fi
fi

exit $status
