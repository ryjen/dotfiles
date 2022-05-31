# load zsh config files
config_files=(~/.zsh/**/*.zsh(N))
for file in ${config_files}
do
  if ! [[ $file =~ run-once ]]; then
    source $file
  fi
done

