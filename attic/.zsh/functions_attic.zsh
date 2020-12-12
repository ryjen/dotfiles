export ATTIC_LAST_BACKUP_FILE=${HOME}/.local/attic_last_backup

# Read date of last execution on filesystem and print it.
#
# $1 - max delay since last backup in days. Over this period, output is printed
#      in red. Default: 2
attic_last_backup() {
    if [ ! -f $ATTIC_LAST_BACKUP_FILE ]; then
        return
    fi
    local max_delay="${1:-2}"
    color=`tput setaf 1`  # red
    local attic_last_backup_date=`more $ATTIC_LAST_BACKUP_FILE`
    local days_since_last_backup=`echo $(( ($(date +%s) - $(date --date=${attic_last_backup_date} +%s) )/(60*60*24) ))`
    case $days_since_last_backup in
        [0-$max_delay])
            color=""
            ;;
    esac
    echo "Last backup:" ${color}${attic_last_backup_date}
}


main() {
    attic_last_backup
}
main "$@"
