#!/bin/sh

schema=$1; shift
for f in $@
do
 if xmllint --schema $schema --noout $f; then
 	false
 	exit
 fi
done
