#!/bin/bash
#source ~/.bash_profile

if type -p java; then
    echo "Found java executable in the PATH"
    _java=java
elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
    echo "Found java executable in $JAVA_HOME"     
    _java="$JAVA_HOME/bin/java"
else
    echo "No Java on this computer! Bad!!!"
fi

if [[ "$_java" ]]; then
    version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo "Version: $version"
    if [[ "$version" > "1.8" ]]; then
        echo "Version is >= 1.8 already. Good :-)"
    else         
        echo "Version is less than 1.8. Bad :-("
        echo "Lets change it to 1.8"
        source ~/.bash_profile
        setjdk 1.8
         version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
         echo "Version now is: $version in the script execution environment :-)"
    fi
fi

