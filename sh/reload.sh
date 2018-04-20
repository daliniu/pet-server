#!/bin/bash
#set -x

dir=$(dirname $0)
if [ -e $dir/base.sh ]
then
    source $dir/base.sh
else
    echo "base.sh is not exist."
    echo "failed"
    exit 1
fi

usage () {
cat <<EOF
    Usage: $0 [OPTIONS]
    new       Update new changed module    
    all       Update all modules 
EOF
    exit 1
}

update_all() {
	c2config
    cat $ROOT/../scripts/RenewAll.lua > $ROOT/../scripts/Renew.lua 
    pids=`ps aux | grep ${Game} | grep -v grep | awk '{print $2}'`
    for pid in $pids
    do
        kill -SIGUSR2 $pid
    done
    echo "ok"
}

update_new() {
    if [ ! -e Renew.lua ] ; then
        touch Renew.lua
    fi
    newlines=`find -type f -name "*.lua" -cnewer Renew.lua | wc -l`
    if [ $newlines -gt 0 ] ; then
        ./check.sh > tmp.lua
        cat tmp.lua > Renew.lua
        if [ ${DBUSER} == "test" ]
        then
            kill -SIGUSR2 `pgrep Lemure`   
        fi
        kill -SIGUSR2 `pgrep ${agent}_${sid}_Lemure`
        rm -rf tmp.lua
        echo ">>> update ok"
    else
        echo ">>> no update"
    fi
}

hotupdate() {
    for arg do
        case "$arg" in
            help) usage ;;
            new) update_new ;;
            all) update_all ;;
            *) echo "Invalid argument $arg" ;;
        esac
    done
}

#hotupdate "$@"
hotupdate all

