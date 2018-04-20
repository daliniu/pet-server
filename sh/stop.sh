#!/bin/sh

dir=$(dirname $0)
if [ -e $dir/base.sh ]
then
    source $dir/base.sh
else
    echo "base.sh is not exist."
    echo "failed"
    exit 1
fi


sn=`ps -ef | grep $ROOT/keep.sh | grep -v grep |awk '{print $2}'`
if [ "${sn}" != "" ]
then
    kill -9 $sn 
fi
run_c2ctl stop

