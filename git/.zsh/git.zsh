
GIT_CONF_HOME="${HOME}/.config/git"

[ -d ${GIT_CONF_HOME} ] || exit 0

GIT_CONFD="${GIT_CONF_HOME}/conf.d"

GIT_CONFD_INCLUDES="${GIT_CONF_HOME}/includes.conf"

echo "" > ${GIT_CONFD_INCLUDES}

for c in ${GIT_CONFD}/*; do
  git config --file ${GIT_CONFD_INCLUDES} --add include.path ${c}
done

