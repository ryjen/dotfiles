
type kubectl >/dev/null 2>&1

if [ $? -eq 0 ]; then

  source <(kubectl completion zsh)

  alias k=kubectl
  compdef __start_kubectl k
fi