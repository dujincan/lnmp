# auto lnmp for centos7.4
tools=/server/tools  # 软件解压目录
apps=/application    # 软件安装目录
log=/tmp/lnmp.log    # 软件安装过程的log


mysql=mysql-5.7.24   # mysql压缩包名字去掉tar.gz
boost=boost_1_59_0   # boost压缩包名字去掉tar.gz
mysqluser=mysql      # 运行mysql的用户
data=/data/mysql     # mysql数据目录
dbrootpwd=dbrootpwd  # mysql root密码


nginx=nginx-1.15.8   # nginx压缩包名字去掉tar.gz
nginxuser=www        # 运行nginx的用户
lnmp=`pwd`           # 脚本和软件压缩包存储目录


php=php-7.3.0        # php压缩包名字去掉tar.gz
libzip=libzip-1.2.0  # libzip压缩包名字去掉tar.gz
