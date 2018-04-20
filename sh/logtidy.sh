#!/bin/sh
# tidy all log fiels into dir 
# run every 1 min

if [ -r /etc/profile -a -x /etc/profile ] ; then
    . /etc/profile
fi

ROOT=$(cd `dirname $0`;pwd)
cd $ROOT/../bin/logs
files=`find . -maxdepth 1 -type f -mmin +5 -name "game_*_*.log"`
for f in $files 
do
    d=`echo $f | cut -d '_' -f2`
    if [ ! -d $d ] ; then
        mkdir $d
    fi
    mv $f ./$d
done

