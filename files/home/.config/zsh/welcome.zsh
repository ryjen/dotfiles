# Sourced by the Home Manager Zsh configuration; not a login hook for services.
_dotfiles_terminal_welcome() {
  [[ $- == *i* && -t 0 && -t 1 && -t 2 && $EUID != 0 ]] || return 0
  [[ -n ${TERM:-} && ${TERM:-} != dumb && -z ${CI:-} ]] || return 0
  [[ ${DOTFILES_WELCOME:-1} != 0 && -z ${DOTFILES_WELCOME_SHOWN:-} ]] || return 0
  [[ -z ${SSH_CONNECTION:-}${SSH_TTY:-}${SSH_CLIENT:-} || ${DOTFILES_WELCOME:-} == 1 ]] || return 0

  local canonical="$1" directory="$2" profile="$3" sed_bin="$4" date_bin="$5"
  local banner="$canonical" day index colorizer=cat
  set -- "$canonical" "$directory/digital-sovereignty.txt" "$directory/unix.txt" "$directory/retro.txt"
  if [[ $profile == dubnium ]]; then
    set -- "$@" "$directory/dubnium.txt"
  fi

  case ${DOTFILES_MOTD:-random} in
    random)
      shift "$(( RANDOM % $# ))"
      banner="$1"
      ;;
    daily)
      day=$("$date_bin" +%j) || day=001
      index=$(( (10#$day - 1) % $# ))
      shift "$index"
      banner="$1"
      ;;
    micrantha) ;;
    digital-sovereignty|unix|retro|dubnium)
      banner="$directory/$DOTFILES_MOTD.txt"
      ;;
    *) ;; # Unknown selectors use the canonical artwork.
  esac

  [[ -r $banner ]] || banner="$canonical"
  if [[ -z ${NO_COLOR:-} ]] && command -v lolcat >/dev/null 2>&1; then
    colorizer=lolcat
  fi
  export DOTFILES_WELCOME_SHOWN=1
  {
    # Strip only SGR codes from the existing pre-coloured static artwork.
    "$sed_bin" -E $'s/\e\\[[0-9;]*m//g' "$banner"
    if command -v fortune >/dev/null 2>&1 && command -v cowsay >/dev/null 2>&1; then
      printf '\n'
      command fortune -s | command cowsay -f www
    fi
  } | command "$colorizer" || true

  if command -v task >/dev/null 2>&1; then
    if [[ -n ${NO_COLOR:-} ]]; then
      command task rc.color=off todo || true
    else
      command task todo || true
    fi
  fi
}
_dotfiles_terminal_welcome "$@"
unset -f _dotfiles_terminal_welcome
