
type exenv > /dev/null

if [ $? = 0 ]; then
  eval "$(exenv init -)"
fi
