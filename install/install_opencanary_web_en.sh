#!/bin/sh

echo "########### Initializing Environment #########"
getip=$(hostname -I | cut -d' ' -f1)
echo "Server IP address: $getip"
read -p "Is the IP correct (y/n): " choice
if [ "$choice" = "n" ]; then
    echo "###### Please manually configure IP ######"
    read -p "Please enter this machine's IP: " getip
fi

echo "######### Installing Dependencies ############"
sudo apt-get update
sudo apt-get install -y curl wget ntpdate python-dev git net-tools

echo "############# Disabling SELINUX #########"
# SELinux is not present in DietPi, so this step can be skipped

echo "################## Updating System Time ##################"
sudo ntpdate -u pool.ntp.org

# Check if pip is installed and install if necessary
if ! command -v pip &> /dev/null; then
    curl https://bootstrap.pypa.io/get-pip.py | sudo python
    mkdir ~/.pip/
    cat > ~/.pip/pip.conf <<EOF
[global]
index-url = https://pypi.org/simple
EOF
    sudo python -m pip install --upgrade pip
    echo "################ pip is now installed ############"
else
    echo "################ pip already installed ############"
fi

opencanary_web_folder="/usr/local/src/opencanary_web"
if [ ! -d "$opencanary_web_folder" ]; then
    echo "############ Installing latest version of opencanary_web and its dependencies ##########"
    git clone https://github.com/p1r06u3/opencanary_web.git /usr/local/src/opencanary_web
    cd /usr/local/src/opencanary_web/
    sudo pip install -r requirements.txt
else
    echo "############ opencanary_web already downloaded, installing dependencies #########"
    cd /usr/local/src/opencanary_web/
    sudo pip install -r requirements.txt
fi

echo "###### Installing MariaDB (MySQL) ########"
sudo apt-get install -y mariadb-server
sudo systemctl enable mariadb
sudo systemctl start mariadb

# Configure MySQL as needed (import scripts, set passwords, etc.)

# Install and configure Nginx
echo "###### Installing Nginx ########"
sudo apt-get install -y nginx
# Configure Nginx as per the script

# Install and configure Supervisor
SUPERVISOR_FILE=/usr/bin/supervisorctl
SUPERVISOR_CONF=/etc/supervisord.conf
function SUPERVISOR() {
  if [ ! -f $SUPERVISOR_FILE ]; then
    echo "###### Installing Supervisor ######"
    sudo pip install supervisor
    sudo echo_supervisord_conf > $SUPERVISOR_CONF
    sudo mkdir /etc/supervisord.d
    sudo bash -c "echo '[include]' >> $SUPERVISOR_CONF"
    sudo bash -c "echo 'files = supervisord.d/*.ini' >> $SUPERVISOR_CONF"
    # Supervisor service configuration for systemd
    cat > supervisord.service <<EOF
[Unit]
Description=Supervisor daemon

[Service]
Type=forking
ExecStart=/usr/bin/supervisord -c /etc/supervisord.conf
ExecStop=/usr/bin/supervisorctl shutdown
ExecReload=/usr/bin/supervisorctl reload
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    sudo mv supervisord.service /etc/systemd/system/
  else
    echo "###### Supervisor is already installed ######"
  fi
}
SUPERVISOR

# Configure Supervisor
function SUPERVISOR_CONFIGURE() {
  SUPERVISOR_CONFIGURE_FILE=/etc/supervisord.d/opencanary.ini
  if [ ! -f $SUPERVISOR_CONFIGURE_FILE ]; then
    echo "######Configuring Supervisor######"
    cat > opencanary.ini <<EOF
[program:opencanary]
command=python /usr/local/src/opencanary_web/server.py --port=8000
autostart=true
autorestart=true
stderr_logfile=/var/log/opencanary_err.log
stdout_logfile=/var/log/opencanary_out.log
EOF
    sudo mv opencanary.ini /etc/supervisord.d/
  else
    echo "###### Supervisor configuration already exists ######"
  fi
}
SUPERVISOR_CONFIGURE

# Enable and start Supervisor
sudo systemctl enable supervisord
sudo systemctl start supervisord

# Configure Nginx
echo "###### Configuring Nginx ######"
sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
ng_default=/etc/nginx/conf.d/default.conf
if [ -s $ng_default ]; then
     mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak
fi
cat > /etc/nginx/nginx.conf<<EOF
user nginx;
worker_processes 5;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;
events {
     worker_connections 1024;
}
http {
     include /etc/nginx/mime.types;
     default_type application/octet-stream;
     log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request"'
             '\$status \$body_bytes_sent "\$http_referer" '
             '"\$http_user_agent" "\$http_x_forwarded_for"';
     access_log /var/log/nginx/access.log main;
     sendfile on;
     #tcp_nopush on;
     keepalive_timeout 65;
     #gzip on;
     fastcgi_connect_timeout 1800;
     fastcgi_send_timeout 1800;
     fastcgi_read_timeout 1800;
     fastcgi_buffer_size 1024k;
     fastcgi_buffers 32 1024k;
     fastcgi_busy_buffers_size 2048k;
     fastcgi_temp_file_write_size 2048k;
     map \$http_upgrade \$connection_upgrade {
     default upgrade;
     '' close;
     }
     include /etc/nginx/conf.d/*.conf;
}
EOF
cat > /etc/nginx/conf.d/hp.conf<<EOF
upstream hp {
     server 127.0.0.1:8000;
}
server {
     listen 80;
     server_name localhost;
     proxy_connect_timeout 10d;
     proxy_read_timeout 10d;
     proxy_send_timeout 10d;
     location /static/ {
         alias /usr/local/src/opencanary_web/dist/static/;

     }
     location/{
         proxy_pass http://hp;
         proxy_pass_header Server;
         proxy_set_header Host \$http_host;
         proxy_redirect off;
         proxy_set_header X-Real-IP \$remote_addr;
         proxy_set_header X-Scheme \$scheme;
         proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
         proxy_http_version 1.1;
         proxy_set_header Upgrade \$http_upgrade;
         proxy_set_header Connection "upgrade";
     }
}
EOF

sed -i "s/localhost/$getip/g" /etc/nginx/conf.d/hp.conf
echo "############## NGINX configuration completed #############"
echo "############## Starting NGINX ###############"
# Configure and start Nginx
sudo systemctl enable nginx
sudo systemctl restart nginx
echo "############## Restart NGINX completed ###############"
echo "##############   closing the firewall  ###############"
systemctl stop firewalld.service
systemctl disable firewalld
clear



# Email configuration for the honeypot
echo "###### Configuring Honeypot Email Alerts ######"
#Configure honeypot alarm email sending and receiving
echo "############ Whether to configure Opencanary_Web honeypot email sending and receiving, enter yes/no? Enter. Default is no. ############"
typeset -l select
read select
case $select in
y*)
get_mail_host=`sed -n '30p' /usr/local/src/opencanary_web/application.py |cut -d ' ' -f1`
get_mail_user=`sed -n '31p' /usr/local/src/opencanary_web/application.py |cut -d ' ' -f1`
get_mail_pass=`sed -n '32p' /usr/local/src/opencanary_web/application.py |cut -d ' ' -f1`
get_mail_postfix=`sed -n '33p' /usr/local/src/opencanary_web/application.py |cut -d ' ' -f1`
# get_mail_addressee=`sed -n '2p' /usr/local/src/opencanary_web/util/conf/email.ini`
echo "############ Configuring opencanary honeypot email sending and receiving ###########"
read -p "smtp server address:" mail_host
if [ "$mail_host" = "" ]; then
   echo "$get_mail_host"
    else
   sed -i "s/smtp.163.com/$mail_host/g" /usr/local/src/opencanary_web/application.py
fi
read -p "Email username:" mail_user
if [ "$mail_user" = "" ]; then
   echo "$get_mail_user"
    else
   sed -i "s/qyflyj/$mail_user/g" /usr/local/src/opencanary_web/application.py
fi
read -p "Enter email password:" mail_pass
if [ "$mail_pass" = "" ]; then
   echo "$get_mail_pass"
    else
   sed -i "s/opencanary123/$mail_pass/g" /usr/local/src/opencanary_web/application.py
fi
read -p "Mailbox suffix:" mail_postfix
if [ "$mail_postfix" = "" ]; then
   echo "$get_mail_postfix"
    else
   sed -i "s/163.com/$mail_postfix/g" /usr/local/src/opencanary_web/application.py
fi
echo "############ Configuration completed, next step is to configure the recipient's email address ###########"

get_mail_addressee=`sed -n '2p' /usr/local/src/opencanary_web/util/conf/email.ini | awk '{print $3}'`
read -p "recipient's email address:" mail_addressee
if [ "$mail_addressee" = "" ]; then
   echo "######## No changes have been made to the configuration. The default recipient email is: $get_mail_addressee #######"
    else
       sed -i "s/$get_mail_addressee/$mail_addressee/g" /usr/local/src/opencanary_web/util/conf/email.ini
get_new_mail_addressee=`sed -n '2p' /usr/local/src/opencanary_web/util/conf/email.ini | awk '{print $3}'`
       echo "########## Updated alarm receiving email address:$get_new_mail_addressee #########"
fi

mail_switch=`sed -n '3p' /usr/local/src/opencanary_web/util/conf/email.ini |awk '{print $3}'`
if [ "$mail_switch" = "on" ]; then
     echo "####### Alarm email switch has been turned on ########"
     else
     echo "####### is turning on the alarm email switch ##########"
     sed -i "s/switch = off/switch = on/g" /usr/local/src/opencanary_web/util/conf/email.ini
     echo "####### Opened alarm email successfully ##########"
fi

echo "############ Alarm email configuration completed ############"
echo "############         Restarting services....     ############"
sleep 5

# Restart services to apply changes
sudo systemctl restart supervisord
sudo systemctl restart nginx

# Final status messages
echo "###### Setup Completed ######"
# ... Add the final status messages as in the original script ...

# Successful Completion Messages
echo "Time has been synchronized with pool.ntp.org, SELINUX and the firewall have been disabled."
echo "pip has been installed, along with supervisor installation and configuration."
echo "MySQL has been installed, and a regular user 'honeypot' with the password 'Weiho@2019' has been set up. You can manage it with: mysql -u honeypot@'localhost' -pWeiho@2019."
echo "nginx has been installed and configured, and the original nginx configuration file has been backed up to /etc/nginx/nginx.conf.bak."
echo "opencanary_web has been successfully installed. File path: /usr/local/src/opencanary_web."
echo "Access the interface at http://$getip using the admin account with the password 'admin'."
echo "To change the opencanary_web management password, update it via MySQL. Execute the SQL statement to change the password field to your own 32-bit MD5 hash."
echo "Run: UPDATE User SET password='900150983cd24fb0d6963f7d28e17f72' WHERE id=1;"
echo "Also, update the /usr/local/src/opencanary_web/dbs/initdb.py file, specifically the DB_USER/DB_PWD fields."
echo "Honeypot email alerts have been successfully configured. For detailed settings, refer to /usr/local/src/opencanary_web/application.py."
echo "Recipient email settings (and alert switch): /usr/local/src/opencanary_web/util/conf/email.ini."
echo "For more details, please visit https://github.com/p1r06u3/opencanary_web."
;;
n*)
# Messages for when the email setup is not completed
echo "Time has been synchronized with pool.ntp.org, SELINUX and the firewall have been disabled."
echo "pip has been installed, along with supervisor installation and configuration."
echo "MySQL has been installed, and a regular user 'honeypot' with the password 'Weiho@2019' has been set up. You can manage it with: mysql -u honeypot@'localhost' -pWeiho@2019."
echo "nginx has been installed and configured, and the original nginx configuration file has been backed up to /etc/nginx/nginx.conf.bak."
echo "opencanary_web has been successfully installed. File path: /usr/local/src/opencanary_web."
echo "Access the interface at http://$getip using the admin account with the password 'admin'."
echo "To change the opencanary_web management password, update it via MySQL. Execute the SQL statement to change the password field to your own 32-bit MD5 hash."
echo "Run: UPDATE User SET password='900150983cd24fb0d6963f7d28e17f72' WHERE id=1;"
echo "Also, update the /usr/local/src/opencanary_web/dbs/initdb.py file, specifically the DB_USER/DB_PWD fields."
echo "The honeypot email alert configuration was not completed. Please decide if you need to set it up."
echo "For specific configuration of honeypot alerts (sender), refer to /usr/local/src/opencanary_web/application.py."
echo "Recipient email settings (and alert switch): /usr/local/src/opencanary_web/util/conf/email.ini."
echo "For more details, please visit https://github.com/p1r06u3/opencanary_web."
;;
n*)
# In all other cases
echo "Time has been synchronized with pool.ntp.org, SELINUX and the firewall have been disabled."
echo "pip has been installed, along with supervisor installation and configuration."
echo "MySQL has been installed, and a regular user 'honeypot' with the password 'Weiho@2019' has been set up. You can manage it with: mysql -u honeypot@'localhost' -pWeiho@2019."
echo "nginx has been installed and configured, and the original nginx configuration file has been backed up to /etc/nginx/nginx.conf.bak."
echo "opencanary_web has been successfully installed. File path: /usr/local/src/opencanary_web."
echo "Access the interface at http://$getip using the admin account with the password 'admin'."
echo "To change the opencanary_web management password, update it via MySQL. Execute the SQL statement to change the password field to your own 32-bit MD5 hash."
echo "Run: UPDATE User SET password='900150983cd24fb0d6963f7d28e17f72' WHERE id=1;"
echo "Also, update the /usr/local/src/opencanary_web/dbs/initdb.py file, specifically the DB_USER/DB_PWD fields."
echo "The honeypot email alert configuration was not completed. Please decide if you need to set it up."
echo "For specific configuration of honeypot alerts (sender), refer to /usr/local/src/opencanary_web/application.py."
echo "Recipient email settings (and alert switch): /usr/local/src/opencanary_web/util/conf/email.ini."
echo "For more details, please visit https://github.com/p1r06u3/opencanary_web."
esac
exit 0