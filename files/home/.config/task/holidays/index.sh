#!/usr/bin/env bash

cd "$HOME/.config/task/holidays" || exit 1

for file in holidays*.rc; do
  locale=${file:9:5}
  echo "$locale"
  "$HOME/.task/bin/update-holidays.pl" --locale "$locale" --file "holidays.${locale}.rc"
done
