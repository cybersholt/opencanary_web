# Manual installation

I chose CentOS 7.1 as the Linux server. The reason I chose 7 is that the system's own python environment is 2.7.x, so I don't have to bother with python 2.6 and other dependency issues.

SELINUX should be turned off first:

```bash
vi /etc/selinux/config
```

```bash
SELINUX=disabled
```

Then restart the server to make shutting down SELINUX permanent.

## 1. Tornado installation

1. Download web source code and install dependencies

     ```bash
     cd /usr/local/src/
     git clone https://github.com/p1r06u3/opencanary_web.git
     cd opencanary_web/
     pip install -r requirements.txt
     ```

2. Nginx reverse proxy tornado configuration

     Nginx main configuration file:

     ```bash
     vi /etc/nginx/nginx.conf
     ```

     ```bash
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
         log_format main '$remote_addr - $remote_user [$time_local] "$request"'
                 '$status $body_bytes_sent "$http_referer" '
                 '"$http_user_agent" "$http_x_forwarded_for"';
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
         map $http_upgrade $connection_upgrade {
         default upgrade;
         '' close;
         }
         include /etc/nginx/conf.d/*.conf;
     }
     ```

     Nginx reverse proxy tornado configuration:

     ```bash
     mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak
     ```

     ```bash
     vi /etc/nginx/conf.d/hp.conf
     ```

     ```bash
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
             proxy_set_header Host $http_host;
             proxy_redirect off;
             proxy_set_header X-Real-IP $remote_addr;
             proxy_set_header X-Scheme $scheme;
             proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
             proxy_http_version 1.1;
             proxy_set_header Upgrade $http_upgrade;
             proxy_set_header Connection "upgrade";
         }
     }
     ```

## 2. Install MySQL

1. Download the YUM source rpm installation package from the MySQL official website: <http://dev.mysql.com/downloads/repo/yum/>

     **Download MySQL 5.7 source installation package**

     ```bash
     wget http://dev.mysql.com/get/mysql57-community-release-el7-8.noarch.rpm
     ```

     **Install MySQL source**

     ```bash
     yum localinstall mysql57-community-release-el7-8.noarch.rpm
     or
     rpm -ivh mysql57-community-release-el7-8.noarch.rpm
     ```

     **Check whether the MySQL source is installed successfully**

     ```bash
     yum repolist enabled|grep "mysql.*-community.*"
     ```

     **Install MySQL**

     ```bash
     yum install mysql-server
     ```

     **Start MySQL and set it to start at boot**

     ```bash
     systemctl start mysqld
     systemctl enable mysqld
     systemctl daemon-reload
     ```

     **Modify root local login password**

     After the MySQL installation is completed, a default password is generated for root in the /var/log/mysqld.log file.

     Find the root default password in the following way, and then log in to MySQL to modify it:

     ```bash
     grep 'temporary password' /var/log/mysqld.log
     root@localhost: followed by the default initial password
     M%+#bC>1l%EX
     Log in to MySQL: mysql -u root -p
     Execute the password modification statement: alter user root@localhost identified by 'Nidemima';
     identified by followed by single quotes is your new password
     ```

2. Create MySQL database and table structure

     Switch to the opencanary_web directory

     ```bash
     cd /usr/local/src/opencanary_web
     ```

     Create database and restore table structure

     ```bash
     create database honeypot;
     use honeypot;
     source honeypot.sql;
     ```

     At this time, the default user name and password in the User table in the database are: admin\admin

     If you want to modify the web background login password, please execute the sql statement and replace the password value with your own 32-bit md5:

     ```mysql
     UPDATE User SET password='900150983cd24fb0d6963f7d28e17f72' WHERE id=1;
     ```

3. Modify the web database connection password

     ```bash
     vi /usr/local/src/opencanary_web/dbs/initdb.py
     ```

     ```bash
     DB_PWD = 'huanchengzijidemima'
     ```

     Change to your own MySQL password

4. Single tornado instance startup test

     ```bash
     python server.py --port=80
     ```

     If "Development server is running at <http://0.0.0.0:80/>" is output, and the IP of the access host can display the login background address, the web single instance background is started successfully.

## 3. Installation and configuration supervisor

> Supervisor (<http://supervisord.org/>) is a client/server service developed in Python. It is a process management tool under Linux/Unix systems and does not support Windows systems. It can easily monitor, start, stop, and restart one or more processes. For processes managed by Supervisor, when a process is accidentally killed, Supervisor will automatically restart it after listening to the death of the process. It is very convenient to realize the automatic process recovery function and no longer need to write a shell script to control it.

1. Install supervisor

     ```bash
     yum install supervisor
     ```

2. Set up startup

     ```bash
     systemctl enable supervisord.service
     ```

3. Configuration file

     The configuration file of supervisord is /etc/supervisord.conf

     The custom configuration file directory is /etc/supervisord.d/, and the files in this directory have the suffix .ini

     Here is my supervisor sub-configuration:

     vi /etc/supervisord.d/tornado.ini

     ```ini
     [group:tornadoes]
     programs=tornado-8000

     [program:tornado-8000]
     command=python /usr/local/src/opencanary_web/server.py --port=8000
     directory=/usr/local/src/opencanary_web
     autorestart=true
     redirect_stderr=true
     stdout_logfile=/var/log/tornado.log
     loglevel=debug
     ```

4. Start the supervisor service

     ```bash
     systemctl start supervisord.service
     ```

     Other commonly used commands

     ```bash
     systemctl stop supervisord.service # Stop supervisord
     systemctl restart supervisord.service # Restart supervisord
     ```

5. Start multiple tornado instances

     ```bash
     supervisorctl start tornadoes:*
     ```

     More supervisord client management commands

     ```bash
     supervisorctl status # status
     supervisorctl stop nginx # Stop Nginx
     supervisorctl start nginx # Start Nginx
     supervisorctl restart nginx # Restart Nginx
     supervisorctl reread
     supervisorctl update # Update new configuration
     ```

6. Check whether the application web is started successfully

     ```bash
     ps aux|grep python
     ```

     ```bash
     root 30403 2.1 0.3 256192 30596 ? S 16:08 0:00 python /usr/local/src/opencanary_web/server.py --port=8000
     ```

## 4. Install Nginx reverse proxy tornado

1. Install Nginx

     ```bash
     yum install nginx
     ```

2. Nginx reverse proxy tornado configuration

     nginx main configuration file:
     vi /etc/nginx/nginx.conf

     ```bash
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
         log_format main '$remote_addr - $remote_user [$time_local] "$request"'
                 '$status $body_bytes_sent "$http_referer" '
                 '"$http_user_agent" "$http_x_forwarded_for"';
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
         map $http_upgrade $connection_upgrade {
         default upgrade;
         '' close;
         }
         include /etc/nginx/conf.d/*.conf;
     }
     ```

     nginx reverse proxy tornado configuration:

     ```bash
     mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak
     ```

     ```bash
     vi /etc/nginx/conf.d/hp.conf
     ```

     ```bash
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
             proxy_set_header Host $http_host;
             proxy_redirect off;
             proxy_set_header X-Real-IP $remote_addr;
             proxy_set_header X-Scheme $scheme;
             proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
             proxy_http_version 1.1;
             proxy_set_header Upgrade $http_upgrade;
             proxy_set_header Connection "upgrade";
         }
     }
     ```

3. Start or restart nginx

     Already started, restart nginx;

     If it is not started, start nginx;

     In order for the configuration to take effect.

     ```bash
     systemctl start nginx.service
     systemctl restart nginx.service
     ```

4. Check whether nginx starts successfully

     ps aux|grep nginx

     ```bash
     root 1144 0.0 0.0 56704 1192 ? Ss 16:45 0:00 nginx: master process /usr/sbin/nginx
     nginx 1145 0.0 0.0 61356 2176 ? S 16:45 0:00 nginx: worker process
     nginx 1146 0.0 0.0 61356 2176 ? S 16:45 0:00 nginx: worker process
     nginx 1147 0.0 0.0 61356 2176 ? S 16:45 0:00 nginx: worker process
     nginx 1148 0.0 0.0 61356 2176 ? S 16:45 0:00 nginx: worker process
     nginx 1149 0.0 0.0 61356 2176 ? S 16:45 0:00 nginx: worker process
     root 1151 0.0 0.0 112700 968 pts/1 S+ 16:45 0:00 grep --color=auto nginx
     ```

     Access port 80 of the host IP and check whether it can be accessed and logged in normally.

## 5. Client deployment method

After the deployment of the honeypot management background is completed, a virtual host can be re-enabled to deploy the client.

It is recommended to use Centos7 first, followed by Ubuntu16, because the system is relatively new and the default python environment is 2.7.x, and the class library is also relatively new.

Centos7 minimal installation

```bash
yum -y install epel-release //Install epel extension source
yum -y install libpcap-devel openssl-devel libffi-devel python-devel gcc python-pip gcc-c++
```

Ubuntu16

```bash
sudo apt-get install -y python-pip python-virtualenv libpcap-dev
sudo apt-get install -y build-essential libssl-dev libffi-dev python-dev

```

### 6. Install opencanary client

```bash
cd /usr/local/src/
git clone <https://github.com/p1r06u3/opencanary.git>
cd opencanary/
```

vi opencanary/data/settings.json

* In line 2, the value opencanary-1 of device.node_id represents the node that will alarm in the future. It can be changed to any character such as the host name (you can also leave it unchanged).

     ```bash
     "device.node_id": "opencanary-1",
     ```

* Change line 3, server.ip to the IP of your web server (important).

     Note: If your web terminal is not port 80, you must follow the configured IP with ":port number".

     ```bash
     "server.ip": "172.18.214.121",
     ```

* Change line 4, device.listen_addr to your own local IP (not 127.0.0.1).

     ```bash
     "device.listen_addr": "172.18.214.120",
     ```

Install opencanary

```bash
python setup.py sdist
cd dist
pip install opencanary-0.4.tar.gz
```

### 7. Configure port scanning discovery function

>The port scanning discovery module depends on iptables; it requires rsyslog to generate kern.log logs.

#### 1 Install iptables

```bash
yum install iptables-services
```

#### 2 Configure rsyslog

Control the log generation location through rsyslog: vi /etc/rsyslog.conf

Modify line 50

```bash
kern.* /var/log/kern.log
```

Restart rsyslog

```bash
systemctl restart rsyslog.service
```

### 8. Start and stop opencanary method

If you are installing opencanary for the first time, you need to run opencanaryd --copyconfig first, which will generate the /root/.opencanary.conf configuration file.

* Start command: ```opencanaryd --start```
* Stop command: ```opencanaryd --stop```
* Restart command: ```opencanaryd --restart```
* opencanary log: ```/var/tmp/opencanary.log```

### 9. Uninstall opencanary method

First uninstall the old client

```bash
opencanaryd --stop
rm -rf /root/.opencanary.conf
rm -rf /usr/local/src/opencanary/
pip uninstall opencanary -y
iptables -t mangle -F
```

Install new client

```bash
curl -O <https://raw.githubusercontent.com/p1r06u3/opencanary_web/master/install/install_opencanary_agent.sh>
bash install_opencanary_agent.sh
```

## 11. Report a problem

If any problems occur during installation and use, please click [here](https://github.com/p1r06u3/opencanary_web/issues/new) to provide feedback
