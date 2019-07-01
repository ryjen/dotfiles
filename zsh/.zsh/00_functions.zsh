
# Reset prompt every minute to update hour
function TRAPALRM() {  # don't clear completion items on reset prompt
    if [ "$WIDGET" != "complete-word" ]; then
        zle reset-prompt
    fi
}

function dirwatch() {
    inotifywait -m $1 -e create -e move -e delete |
        while read thepath action file; do
            echo "$action $file"
        done
}

function where() {
    find . -name $@
}

function network_connected() {
  nc -zw1 "google.com" 443 > /dev/null;
}

function command_exists() {
  type $@ > /dev/null;
}

function ssh() {
	/usr/bin/ssh -t "$@" tmux new-session -A -s ryjen-session
}

function psql_history() {
    psql -U postgres -c "SELECT (pg_stat_file('base/'||oid ||'/PG_VERSION')).modification, datname FROM pg_database;"
}

