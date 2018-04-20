#!/bin/bash
#set -x

agent=`cat Config.lua |grep ADMIN_AGENT|awk -F"\"" '{print $2}'`
sid=`grep "DBNAME" Config.lua|awk -F"\"" '{print $2}'|cut -f3 -d"_"`
DBUSER=`grep "DBUSER" Config.lua|awk -F"\"" '{print $2}'`
usage () {
cat <<EOF
    Usage: $0 [OPTIONS]
    new       Update new changed module    
    all       Update all modules 
EOF
    exit 1
}

update_all() {
    cat RenewAll.lua > Renew.lua 
    if [ ${DBUSER} == "test" ]
    then
        kill -SIGUSR2 `pgrep Lemure`
    else
        kill -SIGUSR2 `pgrep Lemure`
        #kill -SIGUSR2 `pgrep ${agent}_${sid}`
    fi
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

hotupdate "$@"

