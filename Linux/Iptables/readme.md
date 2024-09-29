# Vagrant-Ansible стeнд для работы с iptables

## Описание задачи

1. Добавить inetRouter2, который виден(маршрутизируется (host-only тип сети для виртуалки) с хоста или форвардится порт через локалхост.
2. Дефолт в инет оставить через inetRouter.
3. Запустить nginx на centralServer.
4. Пробросить 80й порт на inetRouter2 8080.
5. Реализовать knocking port:
centralRouter может попасть на ssh inetrRouter через knock скрипт.

## Выполнение

*Лабораторный стенд развёрнут на хосте с Windows + WSL2. На Windows установлены Vagrant и VirtualBox. Ansible установлен на WSL.*

*Все файлы для vagrant располагаются в директории windows (win_directory), у меня это - D:\VBox_Projects\iptables\. Команды для работы с vagrant запускаются из той же директории.*

*Все файлы для ansible располагаются в директории wsl (wsl_directory), у меня это - /home/sof/sof/otus_labs/iptables/. Команды для работы с ansible звпускаются из той же директории.*

### 1. Разворачивание стенда при помощи Vagrant. Добавить inetRouter2.

Создан Vagrantfile *(win_directory)* для разворачивания лабороторного стенда из ДЗ по сетям.
Добавлен хост inetRouter2.
Схема реализованной сети:

![Image alt](https://github.com/Sof-Lab/Home_Lab/blob/main/Linux/Iptables/%D0%A1%D1%85%D0%B5%D0%BC%D0%B0%20%D1%81%D0%B5%D1%82%D0%B8.png)

Для выполнения п.1 из ДЗ у inetRouter2 есть настройка сетевого адаптера:
`:host_only => {type: "dhcp", adapter: 3}`.

Для доступа к вм из wsl в Vagrantfile прописан дополнительный проброс порта `ssh-for-wsl` для каждой вм.
В нём нужно указать ip-адрес хоста и желаемый порт ssh для подключения:
```
:wsl =>	[{auto_correct: true, guest: 22, host: 'указать порт для подключения по ssh', host_ip: "указать ip-адреса Windows хоста", id: "ssh-for-wsl"}],
```

### 2. Настройка стенда при помощи Ansible.

В файле staging/hosts.yaml *(wsl_directory)* нужно заполнить переменные для выполнения настройки стенда.
Для подключения к ВМ:
```
    host_ip: 192.168.1.8 # windows host ip
    dir_wsl: /home/sof/otus_labs/iptables/ # directory wsl whith ansible files
    dir_vagrant: /mnt/d/VBox_Projects/iptables/ # directory wsl whith vagrant files
	
	ansible_port: 'указать порт для подключения по ssh' # указывается к каждой вм согласно настройкам в Vagrantfile ":wsl"
```
Также в staging/hosts.yaml *(wsl_directory)* нужно указать ip-адрес inetRouter2, полученный по dhcp, для `host_only`.
Чтобы посмотреть полученный адрес, а также названия сетевых интерфейсов, нужно зайти на inetRouter2:
```
PS D:\VBox_Projects\iptables> vagrant ssh inetRouter2
Last login: Sun Sep 29 16:37:32 2024 from 10.0.2.2
vagrant@inetRouter2:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:8c:69:41 brd ff:ff:ff:ff:ff:ff
    altname enp0s3
    inet 10.0.2.15/24 metric 100 brd 10.0.2.255 scope global dynamic eth0
       valid_lft 85174sec preferred_lft 85174sec
    inet6 fe80::a00:27ff:fe8c:6941/64 scope link
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:c4:72:7c brd ff:ff:ff:ff:ff:ff
    altname enp0s8
    inet 192.168.255.13/30 brd 192.168.255.15 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fec4:727c/64 scope link
       valid_lft forever preferred_lft forever
4: eth2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:6d:97:ff brd ff:ff:ff:ff:ff:ff
    altname enp0s9
    inet 192.168.56.6/24 metric 100 brd 192.168.56.255 scope global dynamic eth2
       valid_lft 574sec preferred_lft 574sec
    inet6 fe80::a00:27ff:fe6d:97ff/64 scope link
       valid_lft forever preferred_lft forever
```
Для выполнения проброса портов к nginx заполнить соответствующие переменные в staging/hosts.yaml *(wsl_directory)*:
```
    nginx_listen_port: 8080
    router_listen_port: 80

    nginx_ip: 192.168.0.2 # centralServer ip
    router_ext_ip: 192.168.56.6 # ip for connect to inetRouter2 from host (from dhcp virtualbox)
    router_int_ip: 192.168.255.13 # internal net ip inetRouter2

    router_ext_interface: eth2 # interface inetRouter2 whith ext_ip
    router_int_interface: eth1 # interface inetRouter2 whith int_ip
```
В файле staging/hosts.yaml *(wsl_directory)* дополнительно прописан localhost для выполнения команд в wsl.
Это требуется, чтобы скопировать ключ private_key для подключения к ВМ из директории windows в директорию wsl.

PLAY `WSL localhost copy private_key` копирует private_key на wsl.

#### 2.1. Дефолт в инет оставить через inetRouter.

PLAY `Configure NET` реализовывает сетевые настройки согласно дз по сети.
В файлах `/etc/netplan/50-vagrant.yaml` сохранен дефолтный маршрут через inetRouter.

### 3. Запустить nginx на centralServer.

PLAY `Configure NGINX` устанавливает и запускает nginx на centralServer.

### 4. Пробросить 80й порт на inetRouter2 8080.

PLAY `Configure FORWARD inetRouter2` осуществляет требуемый проброс, меняя настройки iptables и сохраняя их.

### 4.1. Проверка проброса портов.

С Windows хоста попробуем пройти на router_ext_ip по порту 80:
```
C:\Users\Sof>curl 192.168.56.6:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```
Успешно.

### 5. Реализовать knocking port.

PLAY `Configure KNOCKD inetRouter` настраивает knockd.
PLAY `Configure KNOCKD centralRouter` выкладывает на хост скрипты для открытия и закрытия порта ssh.

#### 5.1. Проверка knocking port.

Для проверки результатов подключусь на inetRouter и centralRouter.
Просмотр настроек iptables inetRouter до реализации стука:
```
vagrant@inetRouter:~$ sudo iptables -nvL --line-numbers
Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
num   pkts bytes target     prot opt in     out     source               destination
1        0     0 ACCEPT     icmp --  *      *       0.0.0.0/0            0.0.0.0/0
2        0     0 ACCEPT     all  --  lo     *       0.0.0.0/0            0.0.0.0/0
3      294  434K ACCEPT     all  --  *      *       10.0.2.2             0.0.0.0/0
4        0     0 ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
5        0     0 DROP       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:22

Chain FORWARD (policy ACCEPT 62 packets, 41494 bytes)
num   pkts bytes target     prot opt in     out     source               destination

Chain OUTPUT (policy ACCEPT 208 packets, 25050 bytes)
num   pkts bytes target     prot opt in     out     source               destination
```
Попытка подключиться по ssh с centralRouter на inetRouter до реализации стука:
```
root@centralRouter:~# ssh 192.168.255.1
```
Подключение не осуществляется.
Запуск скрипта на centralRouter для подключения по ssh к inetRouter:
```
root@centralRouter:~# ./knockd.sh
Knocking on port 7000...
Knocking on port 8000...
Knocking on port 9000...
Port knocking complete, trying to connect via SSH...
The authenticity of host '192.168.255.1 (192.168.255.1)' can't be established.
ED25519 key fingerprint is SHA256:++6pEY2xAUiRCxh/jDRYTcPtu9CRgA2GuAMOhbQrOxg.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.255.1' (ED25519) to the list of known hosts.
root@192.168.255.1's password:
```
Соединение осуществлено.
Просмотр настроек iptables на inetRouter после реализации стука:
```
vagrant@inetRouter:~$ sudo iptables -nvL --line-numbers
Chain INPUT (policy ACCEPT 3 packets, 180 bytes)
num   pkts bytes target     prot opt in     out     source               destination
1        0     0 ACCEPT     icmp --  *      *       0.0.0.0/0            0.0.0.0/0
2        0     0 ACCEPT     all  --  lo     *       0.0.0.0/0            0.0.0.0/0
3      307  435K ACCEPT     all  --  *      *       10.0.2.2             0.0.0.0/0
4       11  2317 ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
5        1    60 ACCEPT     tcp  --  *      *       192.168.255.2        0.0.0.0/0            tcp dpt:22
6        0     0 DROP       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:22

Chain FORWARD (policy ACCEPT 62 packets, 41494 bytes)
num   pkts bytes target     prot opt in     out     source               destination

Chain OUTPUT (policy ACCEPT 231 packets, 28543 bytes)
num   pkts bytes target     prot opt in     out     source               destination
```
Запуск скрипта на centralRouter для закрытия порта ssh inetRouter:
```
root@centralRouter:~# ./close_ssh.sh
Knocking on port 9000...
Knocking on port 8000...
Knocking on port 7000...
Port knocking complete, trying to connect via SSH...
```
Просмотр настроек iptables inetRouter после закрытия ssh:
```
vagrant@inetRouter:~$ sudo iptables -nvL --line-numbers
Chain INPUT (policy ACCEPT 6 packets, 360 bytes)
num   pkts bytes target     prot opt in     out     source               destination
1        0     0 ACCEPT     icmp --  *      *       0.0.0.0/0            0.0.0.0/0
2        0     0 ACCEPT     all  --  lo     *       0.0.0.0/0            0.0.0.0/0
3      320  435K ACCEPT     all  --  *      *       10.0.2.2             0.0.0.0/0
4       13  2421 ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
5        2   120 DROP       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:22

Chain FORWARD (policy ACCEPT 62 packets, 41494 bytes)
num   pkts bytes target     prot opt in     out     source               destination

Chain OUTPUT (policy ACCEPT 246 packets, 29623 bytes)
num   pkts bytes target     prot opt in     out     source               destination
```

#### 5.2. Заметки.

Чтобы не потерять доступ vagrant в iptables inetRouter прописан TASK `Create rule for internal management`.
Чтобы при работе knockd не разрывались текущие установленные соединения прописан TASK `Create rule for RELATED,ESTABLISHED ACCEPT`.