#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

if [ ! -d /www/server/panel/BTPanel ];then
	echo "============================================="
	echo "错误, 5.x不可以使用此命令升级!"
	echo "5.9平滑升级到6.0的命令：curl http://io.bt.sy/install/update_to_6.sh|bash"
	exit 0;
fi

if [ ! -f "/www/server/panel/pyenv/bin/python3" ];then
	echo "============================================="
	echo "错误, 当前面板过旧/py-2.7/无pyenv环境，无法升级至最新版面板"
	echo "请截图 联系 TG群组：@rsakuras 或者 QQ群组：630947024 求助！"
	exit 0;
fi

clear
echo -e " "
echo -e "\033[31m若在使用中发现问题，请及时联系 TG群组：@rsakuras 进行反馈！ \033[0m"
echo -e " "
echo -e "\033[34m赞助商ADS: \033[0m"
echo -e "\033[33m美国洛杉矶CN2GIA服务器-特价促销中-KURUN CLOUD机房直销 \033[0m"
echo -e "\033[33m官网:https://www.kurun.com \033[0m"
echo -e "\033[33m ... ... \033[0m"
echo -e "\033[33m轻云互联 - 美国直连双程CN2GIA精品网 - 香港CN2GIA线路三网 \033[0m"
echo -e "\033[33m官网 : https://www.qingyunl.com \033[0m"
echo -e " "
echo -e "\033[31m感谢你认可本ADS，本脚本纯爱发电，托管服务器也是各位ADS无偿为大家提供，作者提供精力为大家更新 \033[0m"
echo -e "\033[31m注意：本脚本一直是免费的，若是发现收费请立刻重装系统（属于盗取脚本，可能被第三方盗取者插入后门），作者也不支持打赏！ \033[0m"
echo -e " "
sleep 5s

public_file=/www/server/panel/install/public.sh
publicFileMd5=$(md5sum ${public_file} 2>/dev/null|awk '{print $1}')
md5check="acfc18417ee58c64ff99d186f855e3e1"
if [ "${publicFileMd5}" != "${md5check}"  ]; then
	wget -O Tpublic.sh http://io.bt.sy/install/public.sh -T 20;
	publicFileMd5=$(md5sum Tpublic.sh 2>/dev/null|awk '{print $1}')
	if [ "${publicFileMd5}" == "${md5check}"  ]; then
		\cp -rpa Tpublic.sh $public_file
	fi
	rm -f Tpublic.sh
fi
. $public_file

Centos8Check=$(cat /etc/redhat-release | grep ' 8.' | grep -iE 'centos|Red Hat')
if [ "${Centos8Check}" ];then
	if [ ! -f "/usr/bin/python" ] && [ -f "/usr/bin/python3" ] && [ ! -d "/www/server/panel/pyenv" ]; then
		ln -sf /usr/bin/python3 /usr/bin/python
	fi
fi

mypip="pip"
env_path=/www/server/panel/pyenv/bin/activate
if [ -f $env_path ];then
	mypip="/www/server/panel/pyenv/bin/pip"
fi

download_Url=http://io.bt.sy
setup_path=/www

if [ -f "/www/server/panel/data/is_beta.pl" ];then
version=$(curl -Ss --connect-timeout 5 -m 2 https://api.bt.sy/api/panel/beta_version)
else
version=$(curl -Ss --connect-timeout 5 -m 2 https://api.bt.sy/api/panel/get_version)
fi

if [ "$version" = '' ];then
	version='8.0.1'
fi
armCheck=$(uname -m|grep arm)
if [ "${armCheck}" ];then
	version='7.7.0'
fi

if [ "$1" ];then
	version=$1
fi

wget -T 5 -O /tmp/panel.zip $download_Url/install/update/LinuxPanel-${version}.zip
dsize=$(du -b /tmp/panel.zip|awk '{print $1}')
if [ $dsize -lt 10240 ];then
	echo "获取更新包失败，请及时联系 TG群组：@rsakuras 或者 QQ群组：630947024 进行反馈！"
	exit;
fi
unzip -o /tmp/panel.zip -d $setup_path/server/ > /dev/null
rm -f /tmp/panel.zip
wget -O /www/server/panel/data/userInfo.json http://io.bt.sy/install/token/userInfo.json
sed -i 's/[0-9\.]\+[ ]\+www.bt.cn//g' /etc/hosts
sed -i 's/[0-9\.]\+[ ]\+api.bt.sy//g' /etc/hosts
cd $setup_path/server/panel/
check_bt=`cat /etc/init.d/bt`
if [ "${check_bt}" = "" ];then
	rm -f /etc/init.d/bt
	wget -O /etc/init.d/bt $download_Url/install/src/bt7.init -T 20
	chmod +x /etc/init.d/bt
fi
rm -f /www/server/panel/*.pyc
rm -f /www/server/panel/class/*.pyc
#pip install flask_sqlalchemy
#pip install itsdangerous==0.24

pip_list=$($mypip list)
request_v=$(btpip list 2>/dev/null|grep "requests "|awk '{print $2}'|cut -d '.' -f 2)
if [ "$request_v" = "" ] || [ "${request_v}" -gt "28" ];then
	$mypip install requests==2.27.1
fi

openssl_v=$(echo "$pip_list"|grep pyOpenSSL)
if [ "$openssl_v" = "" ];then
	$mypip install pyOpenSSL
fi

#cffi_v=$(echo "$pip_list"|grep cffi|grep 1.12.)
#if [ "$cffi_v" = "" ];then
#	$mypip install cffi==1.12.3
#fi

pymysql=$(echo "$pip_list"|grep pymysql)
if [ "$pymysql" = "" ];then
	$mypip install pymysql
fi

pymysql=$(echo "$pip_list"|grep pycryptodome)
if [ "$pymysql" = "" ];then
	$mypip install pycryptodome
fi

#psutil=$(echo "$pip_list"|grep psutil|awk '{print $2}'|grep '5.7.')
#if [ "$psutil" = "" ];then
#	$mypip install -U psutil
#fi

if [ -d /www/server/panel/class/BTPanel ];then
	rm -rf /www/server/panel/class/BTPanel
fi

chattr -i /etc/init.d/bt
chmod +x /etc/init.d/bt

#echo > /www/server/panel/data/bind.pl
rm -rf /www/server/panel/data/bind.pl

#rm -rf /www/server/panel/class/pluginAuth.cpython-37m-aarch64-linux-gnu.so
rm -rf /www/server/panel/class/pluginAuth.cpython-37m-i386-linux-gnu.so
rm -rf /www/server/panel/class/pluginAuth.cpython-37m-loongarch64-linux-gnu.so
#rm -rf /www/server/panel/class/pluginAuth.cpython-37m-x86_64-linux-gnu.so
rm -rf /www/server/panel/class/pluginAuth.cpython-310-aarch64-linux-gnu.so
rm -rf /www/server/panel/class/pluginAuth.cpython-310-x86_64-linux-gnu.so
#rm -rf /www/server/panel/class/pluginAuth.so
rm -rf /www/server/panel/class/pluginAuth.py

rm -rf /www/server/panel/class/libAuth.aarch64.so
rm -rf /www/server/panel/class/libAuth.glibc-2.14.x86_64.so
rm -rf /www/server/panel/class/libAuth.loongarch64.so
rm -rf /www/server/panel/class/libAuth.x86-64.so
rm -rf /www/server/panel/class/libAuth.x86.so

#rm -rf /www/server/panel/class/PluginLoader.aarch64.Python3.7.so
#rm -rf /www/server/panel/class/PluginLoader.i686.Python3.7.so
#rm -rf /www/server/panel/class/PluginLoader.loongarch64.Python3.7.so
#rm -rf /www/server/panel/class/PluginLoader.so
#rm -rf /www/server/panel/class/PluginLoader.s390x.Python3.7.so
#rm -rf /www/server/panel/class/PluginLoader.x86_64.glibc214.Python3.7.so
#rm -rf /www/server/panel/class/PluginLoader.x86_64.Python3.7.so

echo "====================================="
rm -f /dev/shm/bt_sql_tips.pl
kill $(ps aux|grep -E "task.pyc|main.py"|grep -v grep|awk '{print $2}')
/etc/init.d/bt start
echo 'True' > /www/server/panel/data/restart.pl
pkill -9 gunicorn &
#echo "已成功升级到 [$version]企业版";
echo -e "\033[36m已成功升级到[$version]企业版\033[0m";
echo -e " "
echo -e "\033[31m已经安装完毕，欢迎使用！ \033[0m"  
echo -e " "
echo -e "\033[33m赞助商ADS: \033[0m"
echo -e "\033[33m美国洛杉矶CN2GIA服务器-特价促销中-KURUN CLOUD机房直销 \033[0m"
echo -e "\033[33m官网:https://www.kurun.com \033[0m"
echo -e "\033[33m ... ... \033[0m"
echo -e "\033[33m轻云互联 - 美国直连双程CN2GIA精品网 - 香港CN2GIA线路三网 \033[0m"
echo -e "\033[33m官网 : https://www.qingyunl.com \033[0m"
echo -e " "
echo -e "\033[31m感谢你认可本ADS，本脚本纯爱发电，托管服务器也是各位ADS无偿为大家提供，作者提供精力为大家更新 \033[0m"
echo -e "\033[31m注意：本脚本一直是免费的，若是发现收费请立刻重装系统（属于盗取脚本，可能被第三方盗取者插入后门），作者也不支持打赏！ \033[0m"
echo -e " "
#echo -e " "
#echo -e "\033[36m小提示：从官方版转开心版（登陆密码需要重新设置 bt5命令修改） 若是有建站数据（数据库root密码以及新建的数据库密码需要自行修改，可设置成跟以前一样的密码）\033[0m"
#echo -e " "
#echo -e "\033[36m理由：因为宝塔在授权文件里写了 db_encrypt 调用它进行设置面板密码以及数据库密码加密（所以会变成 BT-0x:vc 这种奇怪加密）并不是被黑了，升到开心版需要自行修改密码恢复！\033[0m"



