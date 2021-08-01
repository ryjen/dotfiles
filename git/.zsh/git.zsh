
GIT_CONF_HOME="${HOME}/.config/git"

[ -d ${GIT_CONF_HOME} ] || return 0

GIT_CONFD="${GIT_CONF_HOME}/conf.d"

GIT_CONFD_INCLUDES="${GIT_CONF_HOME}/includes.conf"

for c in ${GIT_CONFD}/*; do

  grep ${c} ${GIT_CONFD_INCLUDES} >/dev/null 2>&1

  if [ $? -ne 0 ]; then 
    git config --file ${GIT_CONFD_INCLUDES} --add include.path ${c}
  fi
done

