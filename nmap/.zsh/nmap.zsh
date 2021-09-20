
alias hostip='ip address |grep "inet " |grep -v host|xargs|cut -d " " -f 2|cut -d"/" -f1'

alias routerip='ip route |grep "default"|cut -d " " -f 3'

function lanctl() {
  local cmd=$1

  case "$cmd" in
    host)
      hostip
      ;;
    router)
      routerip
      ;;
    list|ls)
      local dest=$(routerip)
      local src=$(hostip)
      nmap -sn $dest/24 | grep "Nmap scan report for" | grep -v $src |grep -v $dest| cut -d " " -f 5
      ;;
    scan)
      local target=$2
      if [ -z "$target" ]; then
        echo "Scan which target (see: lanctl list)"
        return 1
      fi
      nmap -T4 -A $target | grep -v Nmap
      ;;
    mac)
      ip link show | grep ether | xargs | cut -d" " -f2
      ;;
    *)
      >&2 echo "Syntax: lanctl host|router|list|scan|mac"
      ;;
  esac
}
