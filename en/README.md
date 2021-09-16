## 1. Introduction to web server

Tornado+Vue+Mysql+APScheduler+Nginx+Supervisor

### 1. Architecture diagram

![Architecture diagram](https://raw.githubusercontent.com/p1r06u3/opencanary_web/master/docs/images/honeypot.png)

### 2. Function display

#### 2.1 Login page

![log in page](https://raw.githubusercontent.com/p1r06u3/opencanary_web/master/docs/images/login.png)

#### 2.2 Dashboard

![dash board](https://raw.githubusercontent.com/p1r06u3/opencanary_web/master/docs/images/dashboard.png)

#### 2.3 Host status

![Host Status](https://raw.githubusercontent.com/p1r06u3/opencanary_web/master/docs/images/hoststatus.png)

#### 2.4 Attack list

![Attack list](https://raw.githubusercontent.com/p1r06u3/opencanary_web/master/docs/images/attacklist.png)

#### 2.5 Filter the list

![Filter list](https://raw.githubusercontent.com/p1r06u3/opencanary_web/master/docs/images/filterlist.png)

#### 2.6 Mail configuration

![Mail configuration](https://raw.githubusercontent.com/p1r06u3/opencanary_web/master/docs/images/mailconf.png)

#### 2.7 Whitelist ip

![Whitelist ip](https://raw.githubusercontent.com/p1r06u3/opencanary_web/master/docs/images/whiteiplist.png)

## Two, installation method

You can choose to automate the installation through a script, or you can choose to install it manually.

### 1. Automated installation

- [More worry-free and labor-saving automatic installation method](/docs/install/Linux_AutoInstall.md)

### 2. Manual installation

- [Let you know more about the manual installation of honeypots](/docs/install/Manual_Installation.md)

### 3. Some instructions for use

- [Some instructions for backend and client](/docs/install/Document.md)

## 3. Information that can be counted in the background

1. ftp login attempt;
2. http access request;
3. http login request;
4. ssh to establish a connection;
5. ssh remote version sending;
6. ssh login attempt;
7. Telnet login attempt;
8. Full port (SYN) scan recognition;
9. NMAP OS scanning recognition;
10. NMAP NULL scanning recognition;
11. NMAP XMAS scanning recognition;
12. NMAP FIN scanning recognition;
13. mysql login attempt;
14. git clone request;
15. ntp monlist request (closed by default);
16. redis command request;
17. TCP connection request;
18. vnc connection request;
19. rdp protocol windows remote login;
20. snmp scan;
21. sip request;
22. mssql login sql account authentication;
23. mssql login win identity authentication;
24. http proxy login attempt;

## 4. Project Acknowledgements

1. **Thinkst Applied Research**

2. **Angel user group and open source contributors** :

    @Weiho @kafka @Pa5sw0rd @Cotton @Aa.Kay @冷白开@YongShao @Lemon

## Five, report problems

If there are any problems during the use, please click [here to](https://github.com/p1r06u3/opencanary_web/issues/new) feedback
