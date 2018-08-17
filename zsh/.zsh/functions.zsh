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
    find . -name "*${1}*"
}

function test_network() {
  nc -zw1 "google.com" 443 > /dev/null
}

function ssh() {
	/usr/bin/ssh -t "$@" tmux -f .tmux.conf new-session -A -s $(USER)-session
}

function psql_history() {
    psql -U postgres -c "SELECT (pg_stat_file('base/'||oid ||'/PG_VERSION')).modification, datname FROM pg_database;"
}

ppgrep() {
    if [[ $1 == "" ]]; then
        PERCOL=percol
    else
        PERCOL="percol --query $1"
    fi
    ps aux | eval $PERCOL | awk '{ print $2 }'
}

ppkill() {
    if [[ $1 =~ "^-" ]]; then
        QUERY=""            # options only
    else
        QUERY=$1            # with a query
        [[ $# > 0 ]] && shift
    fi
    ppgrep $QUERY | xargs kill $*
}
