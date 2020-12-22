
if command_exists neomutt; then
  alias mutt='neomutt'
  alias mail='neomutt'
else
  alias mail='mutt'
fi
