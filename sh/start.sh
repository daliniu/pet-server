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

run_c2ctl start

