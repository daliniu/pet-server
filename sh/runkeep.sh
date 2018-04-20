#!/bin/bash 

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
echo $sn
if [ "${sn}" == "" ]
then
	echo "...."
else
	echo ".... ..."
    kill -9 $sn 
fi

#./keep.sh > keep.log 2>&1 &
if hash setsid 2>/dev/null; then
    setsid $ROOT/keep.sh 
else
    ($ROOT/keep.sh &)
fi
#(./keep.sh &)
#nohup ./keep.sh &

echo "ok"

