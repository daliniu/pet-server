#!/bin/sh
#set -x

ROOT=$(cd `dirname $0`;pwd)
HIS_ROOT=$(cd $ROOT;cd ../;pwd)
RUN_OPTIONS="--daemon"
CUR_USER=`whoami`
CUR_DIR=`pwd`
MYOP=""

usage () {
cat <<EOF

    Usage: $0 [OPTIONS]
    start                       Run all process    
    stop                        Stop all process
    restart                     Restart all process
    help                        Print this message 
EOF
    exit 1
}

#logpath="/data/logs/fc_"
agent=`cat $ROOT/../config/Config.lua |grep ADMIN_AGENT|awk -F"\"" '{print $2}'`
sid=`grep "SVRNAME" $ROOT/../config/Config.lua|sed -e "s;SVRNAME=;;"|awk -F\[ '{print$2}'|awk -F\] '{print$1}'`
DBUSER=`grep "DBUSER" $ROOT/../config/Config.lua|awk -F"\"" '{print $2}'`
Game="${agent}_${sid}_Lemure"
if hash md5sum 2>/dev/null; then
    echo "md5sum exists"
else
    echo "md5 -r"
    alias md5sum='md5 -r'
fi

c2config() {
    if [ ! -f $ROOT/../config/Config.lua ] ; then
        echo "failed"
        echo "[error]:你需要重新配置服务器config"
        exit 1
    fi
    if [ -f $ROOT/../scripts/Config.lua ] ; then
        rm -f $ROOT/../scripts/Config.lua
    fi
    cp $ROOT/../config/Config.lua $ROOT/../scripts/
}

stop() {
    pids=`ps aux | grep ${Game} | grep -v grep | awk '{print $2}'`
    for pid in $pids
    do
        kill -2 $pid 
    done
    while true
    do
        pnum=`ps aux | grep ${Game} | grep -v grep | grep -v m3ctl | wc -l`
        if [ $pnum -eq 0 ] ; then
            echo "ok"
            break
        fi
    done
}

run() {
    pnum=`ps aux | grep ${Game} | grep -v grep | grep -v m3ctl | wc -l`
    if [ ! $pnum -eq 0 ] ; then
        echo "[warning] Process ${Game} already running"
        exit 1
    fi

    c2config 
    ulimit -c unlimited
    ulimit -HSn 65535 

    if [ ! -f $ROOT/../bin/${Game} ]
    then
        cp $ROOT/../bin/Lemure $ROOT/../bin/${Game}
        cd $ROOT/../bin
		chmod +x ${Game}
        ./${Game} >  $ROOT/../bin/logs/run.log 2>&1 --daemon
        cd -
    else
        new=`md5sum $ROOT/../bin/Lemure | awk '{print $1}' `
        old=`md5sum $ROOT/../bin/${Game} | awk '{print $1}' `
        if [ "$new" != "$old" ]
        then
            rm -f $ROOT/../bin/${Game}
            cp $ROOT/../bin/Lemure $ROOT/../bin/${Game}
        fi
        cd $ROOT/../bin 
		chmod +x ${Game}
        ./${Game} >  $ROOT/../bin/logs/run.log 2>&1 --daemon
        cd -
    fi
    sleep 3
    let start=`date "+%s"`
    while true
    do
        pnum=`ps aux | grep ${Game} | grep -v grep | grep -v m3ctl | wc -l`
        if [ ! $pnum -eq 0 ] ; then
            echo "ok"
            break
        fi
        let now=`date "+%s"`
        let interval=$[now-start]
        if [ $interval -gt 6 ];then
            echo "failed"
            break
        fi
    done
}



restart() {
    echo "stop Process......"
    stop 
    echo "start Process......"
    run 
}

cleandb() {
    #mongo -utest -ptest123 --eval 'db.char.remove();db.guild.remove();db.BFlower.remove();db.BGuild.remove();db.BRoleLevel.remove();db.BSendFlower.remove();db.magicboxBBS.remove();db.mail.config.remove();db.mail.gm.remove();db.mail.player.remove();db.mail.system.remove();db.market.remove();db.relation.remove()' ming6
    echo "clean db ok"
}

run_c2ctl() {
    for arg do
        case "$arg" in
            help) usage ;;
            start) run ;;
            stop) stop ;;
            restart) restart;;
        esac
    done
}

#ulimit -c unlimited
#ulimit -HSn 65535 

#run_c2ctl "$@"

