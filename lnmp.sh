#!/bin/bash
####################################################
# Author: Jason du
# Mail: jincan.du@outlook.com
# Created Time: 2019-01-09 13:31:47
# Last modified: 2019-01-09 13:31:47
# Name: nginx.sh
# Version: v1.0
# Description: 
####################################################
. /etc/init.d/functions

# system vars
tools=/server/tools
apps=/application
log=/tmp/lnmp.log

# mysql vars
mysql=mysql-5.7.24
boost=boost_1_59_0
mysqluser=mysql
data=/data/mysql
dbrootpwd=dbrootpwd

# nginx vars
nginx=nginx-1.15.8
nginxuser=www
lnmp=`pwd`

# php vars
php=php-7.3.0
libzip=libzip-1.2.0
function nginx() {
    # tar nginx
    [ -d $tools ] || mkdir -p $tools
    tar xf $lnmp/${nginx}.tar.gz -C ${tools}/
    retval=$?
    if [ $retval -eq 0 ]
    then
        action "nginx tar successful" /bin/true
        echo ""
    else
        action "nginx tar fail" /bin/false
        exit $retval
    fi


    # Create user
    if (id -u $nginxuser &>/dev/null)
    then
        action "$nginxuser exists" /bin/true
    else
        useradd www -s /sbin/nologin -M && action "$nginxuser create successful" /bin/true && echo ""
        retval=$?
       if [ $retval -ne 0 ]
       then
           action "$nginxuser create fail" /bin/false
           exit $retval
       fi
    fi

    # Install pcre and openssl

    yum install -y pcre-devel openssl-devel &>/dev/null
    retval=$?
    if [ $? -eq 0 ]
    then
        action "pcre-devel and openssl-devel install successful" /bin/true
        echo ""
    else
        action "pcre-devel and openssl-devel install fail" /bin/false
        exit $retval
    fi

    # Install nginx
    [ -d $apps  ] || mkdir $apps
    cd $tools/$nginx
    ./configure \
        --prefix=$apps/$nginx \
        --user=$ningxuser \
        --group=$nginxuser \
        --with-http_ssl_module \
        --with-http_stub_status_module \
        >$log 2>&1
    retval=$?
    if [ $retval -eq 0 ]
    then
        make >$log 2>&1 && make install >$log 2>&1
        retval=$?
        if [ $retval -eq 0 ]
        then
            ln -s $apps/$nginx $apps/nginx
            action "nginx install successful" /bin/true
            echo ""
        else
            action "nginx install fali" /bin/false
            echo "please check $log"
            exit $retval
        fi
    else
        action "nginx install fail" /bin/false
        echo "please check $log"
        exit $retval
    fi
    # start nginx
    $apps/nginx/sbin/nginx
    retval=$?
    if [ `lsof -i:80|grep nginx|wc -l` -ge 2 ]
    then
        action "nginx start successful" /bin/true
        echo ""
    else
        action "nginx start faile" /bin/false
        exit $retval
    fi
}


function mysql() {
    # Install mysql depend pkg
    yum -y install gcc gcc-c++ ncurses ncurses-devel cmake &>$log
    retval=$?
    if [ $retval -eq 0 ]
    then
        action "mysql depend pkg install successful" /bin/true
        echo ""
    else
        action "mysql depend pkg install fail" /bin/false
        echo "please check $log"
        exit $retval
    fi


    # tar mysql pkg
    tar xf $lnmp/${mysql}.tar.gz -C ${tools}/ &>$log && tar xf ${boost}.tar.gz -C ${tools}/ &>$log
    retval=$?
    if [ $retval -eq 0 ]
    then
        action "tar mysql pkg successful" /bin/true
        echo ""
    else
        action "tar mysql pkg fail" /bin/false
        exit $retval
    fi

    # install mysql
    [ -d $data ] || mkdir -p /data/mysql
    id -u mysql &>/dev/null || useradd -M -s /sbin/nologin $mysqluser
    cd $tools/$mysql
    cmake . -DCMAKE_INSTALL_PREFIX=$apps/$mysql \
        -DMYSQL_DATADIR=$data \
        -DDOWNLOAD_BOOST=1 \
        -DWITH_BOOST=$tools/$boost \
        -DSYSCONFDIR=/etc \
        -DWITH_INNOBASE_STORAGE_ENGINE=1 \
        -DWITH_PARTITION_STORAGE_ENGINE=1 \
        -DWITH_FEDERATED_STORAGE_ENGINE=1 \
        -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
        -DWITH_MYISAM_STORAGE_ENGINE=1 \
        -DENABLED_LOCAL_INFILE=1 \
        -DENABLE_DTRACE=0 \
        -DDEFAULT_CHARSET=utf8mb4 \
        -DDEFAULT_COLLATION=utf8mb4_general_ci \
        -DWITH_EMBEDDED_SERVER=1 &>$log
    retval=$?
    if [ $retval -eq 0 ]
    then
        make install &>$log
        retval=$?
        if [ $retval -eq 0 ]
        then
            ln -s $apps/$mysql $apps/mysql
            action "mysql install successful" /bin/true
            echo ""
        else
            action "mysql make install fail" /bin/false
            echo "please check $log"
            exit $retval
        fi
    else
        action "mysql cmake fail" /bin/false
        echo "please check $log"
        exit $retval
    fi

    # init mysql
    cd $apps/mysql/bin && ./mysqld --initialize-insecure --user=$mysqluser --basedir=$data/mysql --datadir=$data &>$log
    retval=$?
    if [ $retval -eq 0 ]
    then
        action "mysql init successful" /bin/true
        echo ""
        rm -rf /etc/my.cnf
        cp -f $lnmp/my.cnf /etc/my.cnf
        ./mysqld_safe --defaults-file=/etc/my.cnf &>$log &
        retval=$?
        if [ $retval -eq 0 ]
        then
            sleep 5
            action "mysql start successful" /bin/true
            echo ""
            ./mysql -e "grant all privileges on *.* to root@'127.0.0.1' identified by \"$dbrootpwd\" with grant option;" &>$log && \
                ./mysql -e "grant all privileges on *.* to root@'localhost' identified by \"$dbrootpwd\" with grant option;" &>$log
            retval=$?
            if [ $retval -eq 0 ]
            then
                action "mysql change root passwd successful" /bin/true
                echo "root:$dbrootpwd" >/tmp/password.log
                echo "please check password.log"
            else
                action "mysql change root passwd fail" /bin/false
                echo "please check $log"
                exit $retval
            fi
        else
            action "mysql start fail" /bin/false
            echo "please check $log"
            exit $retval
        fi
    else
        action "mysql init fail" /bin/false
        echo "please check $log"
        exit $retval
    fi
}


function php() {
    # tar php
    tar xf $lnmp/${php}.tar.gz -C ${tools}/ &>$log
    retval=$?
    if [ $retval -eq 0 ]
    then
        action "tar php successful" /bin/true
        echo ""
    else
        action "tar php fail" /bin/false
        exit $retval
    fi


    # install php depend pkg
    yum install -y zlib-devel libxml2-devel libjpeg-devel libjpeg-turbo-devel libiconv-devel freetype-devel libpng-devel gd-devel libcurl-devel libxslt-devel &>$log
    retval=$?
    if [ $retval -eq 0 ]
    then
        action "install php depend pkg successful" /bin/true
        echo ""
        tar xf $lnmp/$libzip.tar.gz -C $tools/
        cd $tools/$libzip
        ./configure &>$log && make &>$log && make install &>$log
        retval=$?
        if [ $retval -eq 0 ]
        then
            echo -e "/usr/local/lib64\n/usr/local/lib\n/usr/lib\n/usr/lib64" >>/etc/ld.so.conf
            ldconfig -v &>$log
            cp /usr/local/lib/libzip/include/zipconf.h /usr/local/include/zipconf.h
            action "libzip install successful" /bin/true
            echo ""
        else
            action "libzip install fail" /bin/false
            echo "please check $log"
            exit $retval
        fi
    else
        action "install php depend pkg fail" /bin/false
        echo "please check $log"
        exit $retval
    fi

    # install php
    cd ${tools}/$php 
    ./configure \
    --prefix=$apps/$php \
    --enable-mysqlnd \
    --with-mysqli \
    --with-pdo-mysql \
    --with-mysql-sock=/tmp/mysql.sock \
    --enable-fpm \
    --disable-short-tags \
    --with-curl \
    --with-openssl \
    --with-gd \
    --with-iconv \
    --with-zlib \
    --enable-xml \
    --enable-bcmath \
    --enable-shmop \
    --enable-sysvsem \
    --enable-inline-optimization \
    --enable-mbregex \
    --enable-mbstring \
    --enable-ftp \
    --enable-gd-native-ttf \
    --enable-pcntl \
    --enable-sockets \
    --with-xmlrpc \
    --enable-zip \
    --enable-soap \
    --with-pear \
    --with-gettext \
    --enable-session \
    --with-mcrypt \
    --disable-fileinfo \
    --with-fpm-user=www \
    --with-fpm-group=www &>$log
    retval=$?
    if [ $retval -eq 0 ]
    then
        action "php configure successful" /bin/true
        echo ""
        make &>$log && make install &>$log
        retval=$?
        if [ $retval -eq 0 ]
        then
            action "php make install successful" /bin/true
            echo ""
        else
            action "php make install fail" /bin/false
            echo "please check $log"
            exit $retval
        fi
        
    else
        action "php configure fail" /bin/false
        exit $retval
    fi
    # copy php conf file
    \cp -f php.ini-development $apps/$php/lib/php.ini
    \cp -f $apps/$php/etc/php-fpm.d/www.conf.default $apps/$php/etc/php-fpm.d/www.conf
    \cp -f $apps/$php/etc/php-fpm.conf.default $apps/$php/etc/php-fpm.conf 
    ln -s $apps/$php $apps/php

    # start php
    $apps/php/sbin/php-fpm &>/dev/null
    retval=$?
    if [ $retval -eq 0 ]
    then
        action "php start successful"
        echo ""
    else
        action "php start fail" /bin/false
        exit $retval
    fi
}


function lnmp() {
    nginx
    mysql
    php
    \cp -f $lnmp/nginx.conf $apps/nginx/conf/nginx.conf
    $apps/nginx/sbin/nginx -s reload &>$log
    retval=$?
    if [ $retval -eq 0 ]
    then
        action "lnmp deploy successful" /bin/true
    else
        action "nginx reload fail" /bin/false
        echo "please check $log"
        exit $retval
    fi
    
}



case $1 in 
    lnmp)
        lnmp 
        ;;
    nginx)
        nginx 
        ;;
    mysql)
        mysql
        ;;
    php)
        php
        ;;
    *)
        action "Usage:$0 {lnmp|nginx|mysql|php}" /bin/false 
esac

