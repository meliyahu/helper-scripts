#!/bin/bash

# Stop graphdb if it was started by: run-tern-graphdb.sh script
# By: Mosheh
# Date: 09-10-2019

pid=`cat pidfile`
echo "Killing pid $pid"
kill -9 $pid
sleep 5
echo "Graphdb is stopped."
ps aux | grep java
