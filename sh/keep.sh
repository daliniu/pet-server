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

cnt=0
while(true)
do
sn=`ps -ef | grep $Game | grep -v grep |awk '{print $2}'`
echo $sn
let cnt++
echo $cnt   
if [ "${sn}" = "" ]
then
        run_c2ctl start
        echo start ok !  
else
        echo running  
fi
sleep 10
done


# ./keep.sh > keep.log 2>&1 &
