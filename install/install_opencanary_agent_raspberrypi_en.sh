#!/bin/sh

# Adapted for Raspberry Pi Zero W running DietPi
# Original Author: Sean W. <cybersholt>
# Description: Deploys a single opencanary_web_server
# Website : www.cybersholt.com
# Email : cybersholt@gmail.com
# Github: https://github.com/cybersholt
# Date: 2024-01-12
# Environment: DietPi
#

echo "############### Please confirm that the Web server has been installed ##############"
echo "###############              Raspberry Pi Installer                 ##############"
read -p "Please confirm whether OpenCanary_Web server has been installed (y/n)" choice
if [ "$choice" = "n" ]; then
  echo "######Please install the server before configuring the agent######"
  exit 0
fi

netcard_num=$(ls /sys/class/net/ | grep -v lo | wc -l)

if [ "$netcard_num" -lt 2 ]; then
     ip=$(hostname -I | cut -d' ' -f1)
else
     hostname -I > /tmp/netcard_ip.txt
     ip1=$(sed -n '1p' /tmp/netcard_ip.txt)
     ip2=$(sed -n '2p' /tmp/netcard_ip.txt)
     echo "
     Please select your local IP?(1-3)
     1.$ip1
     2.$ip2
     3.Others
     "
     read -p "Please enter the command (1-3):" ip_choice
     case $ip_choice in
     1)
       echo "Local IP address: $ip1"
       ip=$ip1
       ;;
     2)
       echo "Local IP address: $ip2"
       ip=$ip2
       ;;
     3)
       echo "######Please manually set the IP address of this machine######"
       read -p "Please enter the local IP:" ip
       ;;
     *)
       echo "Please enter a number: 1-3"
       exit 1
       ;;
     esac
fi

read -p "Please confirm whether the local IP: $ip is correct? (y/n)" ipd
if [ "$ipd" = "n" ]; then
  echo "######Please manually set the IP address of this machine######"
  read -p "Please enter the local IP:" ip
fi

read -p "Please enter the Web server IP:" opencanary_web_server_ip
read -p "Please enter the local node name:" opencanary_agent_name
echo "##################################"
echo "Web server IP: $opencanary_web_server_ip"
echo "Local IP address: $ip"
echo "Local node name: $opencanary_agent_name"

echo "###########Installing system dependencies#########"
sudo apt-get update
sudo apt-get install -y libpcap-dev libssl-dev libffi-dev python-dev gcc python-pip gcc g++ ntp git

echo "##################Updating system time##################"
sudo ntpdate -u pool.ntp.org

echo "###########Downloading opencanary_agent#########"
opencanary_folder="/usr/local/src/opencanary"
if [ ! -d "$opencanary_folder" ]; then
     git clone https://github.com/p1r06u3/opencanary.git /usr/local/src/opencanary
else
     cd /usr/local/src/opencanary
     git pull
fi

configure_agent_name=$(sed -n "2p" /usr/local/src/opencanary/opencanary/data/settings.json | awk -F '["]+' '{print $4}')
configure_server_ip=$(sed -n "3p" /usr/local/src/opencanary/opencanary/data/settings.json | awk -F '["]+' '{print $4}')
configure_ip=$(sed -n "4p" /usr/local/src/opencanary/opencanary/data/settings.json | awk -F '["]+' '{print $4}')

sed -i "s/$configure_agent_name/$opencanary_agent_name/g" /usr/local/src/opencanary/opencanary/data/settings.json
sed -i "s/$configure_server_ip/$opencanary_web_server_ip/g" /usr/local/src/opencanary/opencanary/data/settings.json
sed -i "s/$configure_ip/$ip/g" /usr/local/src/opencanary/opencanary/data/settings.json

echo "###########Installing opencanary_agent#########"
cd /usr/local/src/opencanary
sudo python setup.py sdist
cd dist
sudo pip install opencanary-0.4.tar.gz
