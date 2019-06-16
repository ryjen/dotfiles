type fortune > /dev/null

if [ $? -ne 0 ]; then
  return
fi

type cowsay > /dev/null

if [ $? -eq 0 ]; then
  fortune -s | cowsay
else
  fortune
fi
