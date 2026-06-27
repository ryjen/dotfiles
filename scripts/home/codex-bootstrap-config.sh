set -eu

source_dir="${XDG_CONFIG_HOME:-$HOME/.config}/codex"
runtime_dir="$HOME/.codex"
runtime_file="$runtime_dir/config.toml"

mkdir -p "$runtime_dir"
umask 077
tmp_file="$(mktemp "$runtime_dir/.config.toml.tmp.XXXXXX")"
trap 'rm -f "$tmp_file"' EXIT

{
  printf '%s\n' '# Generated during Home Manager activation from configctl Codex layers.'
  printf '%s\n' '# Canonical reconciliation path: configctl init apply codex-config.'
  printf '%s\n' '# Do not edit directly; update ~/.config/codex/local.toml or TOML fragments.'
  printf '\n'

  export LC_ALL=C

  for fragment in "$source_dir"/adopted.d/*.toml; do
    [ -e "$fragment" ] || continue
    cat "$fragment"
    printf '\n'
  done

  for fragment in "$source_dir"/custom.d/*.toml; do
    [ -e "$fragment" ] || continue
    cat "$fragment"
    printf '\n'
  done

  if [ -f "$source_dir/local.toml" ]; then
    cat "$source_dir/local.toml"
    printf '\n'
  fi
} > "$tmp_file"

chmod u+rw,go-rwx "$tmp_file"
mv "$tmp_file" "$runtime_file"
trap - EXIT
