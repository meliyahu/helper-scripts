#!/bin/bash
# Run graph db with some memory settings
# By: Mosheh
# Date: 09-10-2019
#Note: We need to create another instance of graphdb with more memory and CPUs

bin/graphdb -d -p pidfile -Xms1g -Xmx2g -Ddefaut.min.distinct.threshold=100M
echo "Graphdb started."
