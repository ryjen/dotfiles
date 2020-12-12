#! /bin/bash

pushd ~/.config/task/holidays

for i in holidays*rc
do
  locale=${i:9:5}
  echo $locale
  ~/.task/bin/update-holidays.pl --locale $locale --file holidays.${locale}.rc
done

popd

