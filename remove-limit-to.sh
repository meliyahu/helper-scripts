#!/usr/bin/env bash

echo $(uname)
if [ "$(uname)" == "Darwin" ]; then
    echo 'Mac OS X platform'
    sed  -i "" '/limit-to/s/.*/\/\/  limit-to 1/' `find . -name '*.transform'`
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    echo 'Linux'
    sed  -i '/limit-to/s/.*/\/\/  limit-to 1/' `find . -name '*.transform'`
fi

echo "Validating...."

sed -n '/limit-to/p' `find . -name "*.transform"`

echo "All occurances of limit-to have been commented out in all *.transform files."
echo "Done"
