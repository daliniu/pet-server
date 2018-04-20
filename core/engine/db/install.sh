#!/bin/sh

wget http://downloads.mongodb.org/src/mongodb-src-r1.8.3.tar.gz
wget http://download.fedoraproject.org/pub/epel/5/i386/epel-release-5-4.noarch.rpm
wget http://ftp.mozilla.org/pub/mozilla.org/js/js-1.7.0.tar.gz

wget http://sourceforge.net/projects/pcre/files/pcre/8.12/pcre-8.12.tar.bz2

rpm -ivh epel-release-5-4.noarch.rpm

yum -y install scons boost boost-devel

which scons

if [ $? ]; then
		wget http://downloads.sourceforge.net/project/scons/scons/2.0.1/scons-2.0.1-1.noarch.rpm?r=http%3A%2F%2Fwww.scons.org%2F&ts=1314097054&use_mirror=nchc
		rpm -i scons-2.0.1-1.noarch.rpm
fi

tar zxf js-1.7.0.tar.gz
dir=`pwd`
cd js/src/
export CFLAGS="-DJS_C_STRINGS_ARE_UTF8"
make -f Makefile.ref
S_DIST=/usr gmake -f Makefile.ref export
cd $dir

tar xf pcre-8.12.tar.bz2
cd pcre-8.12
./configure --prefix=/usr/local/pcre --enable-utf8 --enable-unicode-properties
make && make install
cd $dir

mkdir /usr/include/js
cp ./dist/include/* /usr/include/js/
cp ./dist/lib64/* /usr/lib64/

cp /usr/local/pcre/include/* /usr/include/
cd /usr/lib64/
ln -s /usr/local/pcre/lib/libpcrecpp.so
ln -s /usr/local/pcre/lib/libpcreposix.so
ln -s /usr/local/pcre/lib/libpcre.so
cd $dir


tar xvf mongodb-src-r1.8.3.tar.gz
cd mongodb-src-r1.8.3

scons all
scons --prefix=/usr/local/mongodb-1.8.3 --noshell --sharedclient --full install
cd /usr/local/mongodb-1.8.3
rm bin/* -f
cp lib64/libmongoclient.so /usr/lib64/

cd /usr/local/
wget http://fastdl.mongodb.org/linux/mongodb-linux-x86_64-1.8.3.tgz
tar xzf mongodb-linux-x86_64-1.8.3.tgz

if [ ! -d "/data/db" ] ; then
		mkdir /data/db
fi

echo "/usr/local/mongodb-linux-x86_64-1.8.3/bin/mongod --fork --auth --logpath=/data/db/log.txt" > /root/mongod_start.sh
chmod a+x /root/mongod_start.sh
echo "ps aux|grep mongod|grep -v grep|awk '{ print \$2}'|xargs kill -2" > /root/mongod_stop.sh
chmod a+x /root/mongod_stop.sh

echo " install OK..."



