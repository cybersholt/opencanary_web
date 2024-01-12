#!/bin/sh
# Original Author: Sean W. <cybersholt>
# Description: An english translation of the original script by Weiho@破晓团队
# Website : https://www.cybersholt.com
# Email : cybersholt@gmail.com
# Github: https://github.com/cybersholt
# Date: 2024-01-12
# Environment: CentOS7.2
# Gratitude: k4n5ha0/p1r06u3/Sven/Null/c00lman/kafka/JK
# deploy single opencanary_web_server
#
# This script is meant for quick & easy install via:
# 'curl -O https://raw.githubusercontent.com/p1r06u3/opencanary_web/master/install/install_opencanary_agent.sh'
# or
# 'wget --no-check-certificate https://raw.githubusercontent.com/p1r06u3/opencanary_web/master/install/install_opencanary_agent.sh'
#
# chmod o+x install_opcanary_agent.sh
# bash install_opcanary_agent.sh
#
#
# ip=192.168.1.100
# ip=`ip add | grep -w inet | grep -v "127.0.0.1"| awk -F '[ /]+' '{print $3}'`
netcard_num=`ls /sys/class/net/ | grep -v lo | wc -l`


echo "############### Please confirm that the Web server has been installed ##############"
echo "###############      and that this server is running CentOS         ##############"
read -p "Please confirm whether OpenCanary_Web server has been installed (y/n)" choice
if [ $choice = n ];then
echo "######Please install the server before configuring the agent######"
exit 0
fi
if [ $netcard_num -lt 2 ];then
     ip=`ip add | grep -w inet | grep -v "127.0.0.1"| awk -F '[ /]+' '{print $3}'`
     else
     #ls /sys/class/net/ | grep -v lo | awk '{print $1}' > /tmp/netcard_ip.txt
     ip add | grep -w inet | grep -v "127.0.0.1"| awk -F '[ /]+' '{print $3}' > /tmp/netcard_ip.txt
     ip1=`sed -n '1p' /tmp/netcard_ip.txt`
     ip2=`sed -n '2p' /tmp/netcard_ip.txt`
     echo "
     Please select your local IP?(1-3)
     1.$ip1
     2.$ip2
     3.Others
     "
     read -p "Please enter the command (1-3):" ip
     n2=`echo $ip | sed 's/[0-9]//g'`
         if [ -n "$n2" ];then
          echo "The input content is not a number."
          exit
         fi
         case $ip in
         1)
          echo "Local IP address:$ip1"
          ip=$ip1
         ;;
         2)
         echo "Local IP address:$ip2"
         ip=$ip2
         ;;
         3)
     echo "######Please manually set the IP address of this machine######"
         read -p "Please enter the local IP:" ip
         ;;
         *)
         echo "Please enter a number: 1-3"
         ;;
         esac
fi

read -p "Please confirm whether the local IP: $ip is correct? (y/n)" ipd
if [ $ipd = n ];then
echo "######Please manually set the IP address of this machine######"
     read -p "Please enter the local IP:" ip
fi


read -p "Please enter the Web server IP:" opencanary_web_server_ip
read -p "Please enter the local node name:" opencanary_agent_name
echo "##################################"
echo Web server IP:$opencanary_web_server_ip
echo Local IP address:$ip
echo local node name:$opencanary_agent_name

echo "###########Installing system dependencies#########"
a=`cat /etc/redhat-release | grep -oP '[[:digit:]]\S*'`
if [ "$a" \< "7.0" ];then
     wget -O /etc/yum.repos.d/CentOS-6.repo http://mirrors.aliyun.com/repo/Centos-6.repo &> /dev/null
     yum clean all
     yum makecache
else
     wget -O /etc/yum.repos.d/CentOS-7.repo http://mirrors.aliyun.com/repo/Centos-7.repo &> /dev/null
     yum clean all
     yum makecache
fi
yum -y -q install epel-release
yum -y -q install libpcap-devel openssl-devel libffi-devel python-devel gcc python-pip gcc-c++ ntpdate git iptables-services

echo "##################Updating system time##################"
ntpdate cn.pool.ntp.org

echo "###########Downloading opencanary_agent#########"
opencanary_folder="/usr/local/src/opencanary"
if [ ! -d $opencanary_folder ]; then
     git clone https://github.com/p1r06u3/opencanary.git /usr/local/src/opencanary
configure_agent_name=`sed -n "2p" /usr/local/src/opencanary/opencanary/data/settings.json | awk -F '["]+' '{print $4}'`
     configure_server_ip=`sed -n "3p" /usr/local/src/opencanary/opencanary/data/settings.json | awk -F '["]+' '{print $4}'`
configure_ip=`sed -n "4p" /usr/local/src/opencanary/opencanary/data/settings.json | awk -F '["]+' '{print $4}'`
sed -i "s/$configure_agent_name/$opencanary_agent_name/g" /usr/local/src/opencanary/opencanary/data/settings.json
     sed -i "s/$configure_server_ip/$opencanary_web_server_ip/g" /usr/local/src/opencanary/opencanary/data/settings.json
sed -i "s/$configure_ip/$ip/g" /usr/local/src/opencanary/opencanary/data/settings.json
     else
configure_agent_name=`sed -n "2p" /usr/local/src/opencanary/opencanary/data/settings.json | awk -F '["]+' '{print $4}'`
     configure_server_ip=`sed -n "3p" /usr/local/src/opencanary/opencanary/data/settings.json | awk -F '["]+' '{print $4}'`
configure_ip=`sed -n "4p" /usr/local/src/opencanary/opencanary/data/settings.json | awk -F '["]+' '{print $4}'`
sed -i "s/$configure_agent_name/$opencanary_agent_name/g" /usr/local/src/opencanary/opencanary/data/settings.json
     sed -i "s/$configure_server_ip/$opencanary_web_server_ip/g" /usr/local/src/opencanary/opencanary/data/settings.json
sed -i "s/$configure_ip/$ip/g" /usr/local/src/opencanary/opencanary/data/settings.json
fi

echo "###########Installing opencanary_agent#########"
     cd /usr/local/src/opencanary/
     python setup.py sdist
     cd /usr/local/src/opencanary/dist
     pip install opencanary-0.4.tar.gz


a=`cat /etc/redhat-release |awk '{print $4}'`
if [ "$a" \< "7.0" ];then
     echo "#############Configure and start rsyslog#############"
     sed -i '50i kern.* /var/log/kern.log' /etc/rsyslog.conf
     /etc/init.d/rsyslog restart
     chkconfig --level 2345 rsyslog on
     else
     echo "#############Configure and start rsys