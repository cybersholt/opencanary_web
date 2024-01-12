# Honeypot management background and honeypot agent automatic installation method under Linux

## Adapted to 64-bit operating system list

*CentOS 7
> Since there are many Linux distributions, it is temporarily impossible to adapt them one by one. If it is not in the above list, please install it manually.

## Install honeypot management backend-Web

> Before installation, please replace the `yum` source yourself

Open a terminal and enter the following command in the root user shell:

```bash
curl -O https://raw.githubusercontent.com/p1r06u3/opencanary_web/master/install/install_opencanary_web.sh
```

Or enter the following command:

```bash
wget --no-check-certificate https://raw.githubusercontent.com/p1r06u3/opencanary_web/master/install/install_opencanary_web.sh
```

Enter after downloading

```bash
bash install_opencanary_web.sh
```

### Installed

After this script is installed, Supervisord/Nginx/Mysql will be started as a system service.

### Start service

```bash
systemctl start supervisord.service
systemctl start nginx.service
systemctl start mariadb.service
```

### Out of service

```bash
systemctl stop supervisord.service
systemctl stop nginx.service
systemctl stop mariadb.service
```

### Restart service

```bash
systemctl restart supervisord.service
systemctl restart nginx.service
systemctl restart mariadb.service
```

### View service running status

```bash
systemctl status supervisord.service
systemctl status nginx.service
systemctl status mariadb.service
```

### Information after installing Web

Visit URL: http://$ip

|Type | Username | Password |
|----- |----- |-----|
| Web account | admin | admin |
| mysql database | honeypot | Weiho@2019 |
| mysql port | 3306| - |
| OpenCanary_Web physical path | /usr/local/src/opencanary_web | - |
| Sender email configuration | /usr/local/src/opencanary_web/application.py | - |
| Recipient email configuration (and alarm switch) | /usr/local/src/opencanary_web/util/conf/email.ini | - |

## Install honeypot client-Agent

Also open a virtual host (VPS) and install the honeypot client.

```bash
curl -O https://raw.githubusercontent.com/p1r06u3/opencanary_web/master/install/install_opencanary_agent.sh
```

Or enter the following command:

```bash
wget --no-check-certificate https://raw.githubusercontent.com/p1r06u3/opencanary_web/master/install/install_opencanary_agent.sh
```

Enter after downloading

```bash
bash install_opencanary_agent.sh
```

Enter the IP of the web server above and wait for the script to complete execution.

Go to the server's Web page to manage http://$ip.

## Report a problem

If any problems occur during use of the installation script, please click [here](https://github.com/p1r06u3/opencanary_web/issues/new) to provide feedback
