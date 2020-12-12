
function gh() {

  local url="https://api.github.com"

  local options=(-H "Authorization: token ${GITHUB_API_TOKEN}")

  while [[ $1 == -* ]]; do
    options+=($1)
    shift
  done

  curl $options "${url}${1}"
}

function gh_setup() {

  local repos=($(gh -s /user/repos | jq -r '.[].ssh_url'))

  for repo in $repos; do
    echo -n "\nClone ${repo}? "
    read res

    case $res in
      Y* | y* )
        git clone $repo
      ;;
    esac
  done
}


