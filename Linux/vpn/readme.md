# Vagrant-Ansible стeнд для работы с VPN

## Описание задачи

1. Настроить VPN между двумя ВМ в tun/tap режимах, замерить скорость в туннелях, сделать вывод об отличающихся показателях.
2. Поднять RAS на базе OpenVPN с клиентскими сертификатами, подключиться с локальной машины на ВМ.

## Выполнение

*Лабораторный стенд развёрнут на хосте с Windows + WSL2. На Windows установлены Vagrant и VirtualBox. Ansible установлен на WSL.*

*Все файлы для vagrant располагаются в директории windows (win_directory), у меня это - D:\VBox_Projects\vpn\. Команды для работы с vagrant запускаются из той же директории.*

*Все файлы для ansible располагаются в директории wsl (wsl_directory), у меня это - /home/sof/sof/otus_labs/vpn/. Команды для работы с ansible звпускаются из той же директории.*

### 1. Разворачивание стенда при помощи Vagrant.

Создан Vagrantfile *(win_directory)* для разворачивания лабороторного стенда.

Для доступа к вм из wsl в Vagrantfile прописан дополнительный проброс порта `ssh-for-wsl` для каждой вм.
В нём нужно указать ip-адрес хоста и желаемый порт ssh для подключения для каждой вм:

```
server.vm.network "forwarded_port", # дополнительный проброс порта для доступа к ВМ из WSL
			auto_correct: true,
			guest: 22,
			host: 'указать порт для подключения по ssh', # Порт для подключения по ssh
			host_ip: "192.168.1.8", # Ip-адрес Windows-хоста
			id: "ssh-for-wsl"

```

### 2. Настройка стенда при помощи Ansible.

В файле staging/hosts.yaml *(wsl_directory)* нужно заполнить переменные для выполнения настройки стенда.
Для подключения к ВМ:
```
    host_ip: 192.168.1.8 # windows host ip
    dir_wsl: /home/sof/otus_labs/vpn/ # directory wsl whith ansible files
    dir_vagrant: /mnt/d/VBox_Projects/vpn/ # directory wsl whith vagrant files
	
	ansible_port: 'указать порт для подключения по ssh' # указывается к каждой вм согласно настройкам в Vagrantfile ":wsl"
```
Также в staging/hosts.yaml *(wsl_directory)* добавлена переменная для выбора режима vpn при выполнении задания 1 `vpn_mode`:
```
vpn_mode: tap # tun/tap
```
В файле staging/hosts.yaml *(wsl_directory)* дополнительно прописан localhost для выполнения команд в wsl.
Это требуется, чтобы скопировать ключ private_key для подключения к ВМ из директории windows в директорию wsl.

PLAY `WSL localhost copy private_key` копирует private_key на wsl.

### 3. Настройка VPN между двумя ВМ в tun/tap режимах.

Для настройки в режиме tun в staging/hosts.yaml *(wsl_directory)* нужно указать значение переменной `vpn_mode`:
```
vpn_mode: tun # tun/tap
```
Затем запустить ansible playbook `vpn.yml`.
После выполнения playbook все необходимые настройки применены.
Замеряем скорость.
На client выполнено:
```
root@client:~# iperf3 -c 10.10.10.1 -t 40 -i 5
Connecting to host 10.10.10.1, port 5201
[  5] local 10.10.10.2 port 39686 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-5.00   sec  80.0 MBytes   134 Mbits/sec  387    359 KBytes
[  5]   5.00-10.00  sec  33.9 MBytes  56.9 Mbits/sec  304    153 KBytes
[  5]  10.00-15.00  sec  30.6 MBytes  51.3 Mbits/sec   53    185 KBytes
[  5]  15.00-20.00  sec  29.8 MBytes  50.0 Mbits/sec    0    277 KBytes
[  5]  20.00-25.00  sec  33.1 MBytes  55.5 Mbits/sec  134    214 KBytes
^C[  5]  25.00-25.26  sec  1.61 MBytes  52.0 Mbits/sec    0    219 KBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-25.26  sec   209 MBytes  69.4 Mbits/sec  878             sender
[  5]   0.00-25.26  sec  0.00 Bytes  0.00 bits/sec                  receiver
iperf3: interrupt - the client has terminated
```
На server выполнено:
```
root@server:~# iperf3 -s &
[2] 5900
root@server:~# iperf3: error - unable to start listener for connections: Address already in use
iperf3: exiting
Accepted connection from 10.10.10.2, port 39672
[  5] local 10.10.10.1 port 5201 connected to 10.10.10.2 port 39686
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-1.00   sec  13.4 MBytes   113 Mbits/sec
[  5]   1.00-2.00   sec  18.3 MBytes   154 Mbits/sec
[  5]   2.00-3.00   sec  18.0 MBytes   151 Mbits/sec
[  5]   3.00-4.00   sec  17.6 MBytes   148 Mbits/sec
[  5]   4.00-5.00   sec  9.69 MBytes  81.3 Mbits/sec
[  5]   5.00-6.00   sec  6.91 MBytes  57.9 Mbits/sec
[  5]   6.00-7.00   sec  6.17 MBytes  51.8 Mbits/sec
[  5]   7.00-8.00   sec  5.92 MBytes  49.7 Mbits/sec
[  5]   8.00-9.00   sec  5.97 MBytes  50.0 Mbits/sec
[  5]   9.00-10.00  sec  8.68 MBytes  72.8 Mbits/sec
[  5]  10.00-11.00  sec  6.28 MBytes  52.7 Mbits/sec
[  5]  11.00-12.00  sec  6.68 MBytes  56.0 Mbits/sec
[  5]  12.00-13.00  sec  6.06 MBytes  50.9 Mbits/sec
[  5]  13.00-14.00  sec  6.13 MBytes  51.4 Mbits/sec
[  5]  14.00-15.00  sec  5.91 MBytes  49.6 Mbits/sec
[  5]  15.00-16.00  sec  5.99 MBytes  50.3 Mbits/sec
[  5]  16.00-17.00  sec  5.97 MBytes  50.1 Mbits/sec
[  5]  17.00-18.00  sec  5.95 MBytes  49.9 Mbits/sec
[  5]  18.00-19.00  sec  5.96 MBytes  50.0 Mbits/sec
[  5]  19.00-20.00  sec  6.02 MBytes  50.5 Mbits/sec
[  5]  20.00-21.00  sec  5.50 MBytes  46.1 Mbits/sec
[  5]  21.00-22.00  sec  6.74 MBytes  56.5 Mbits/sec
[  5]  22.00-23.00  sec  7.36 MBytes  61.8 Mbits/sec
[  5]  23.00-24.00  sec  6.73 MBytes  56.4 Mbits/sec
[  5]  24.00-25.00  sec  6.20 MBytes  52.0 Mbits/sec
[  5]  24.00-25.00  sec  6.20 MBytes  52.0 Mbits/sec
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-25.00  sec   207 MBytes  69.4 Mbits/sec                  receiver
iperf3: the client has terminated
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
^C
[2]+  Exit 1                  iperf3 -s
```
Для настройки в режиме tap в staging/hosts.yaml *(wsl_directory)* нужно указать значение переменной `vpn_mode`:
```
vpn_mode: tap # tun/tap
```
Затем запустить ansible playbook `vpn.yml`, достаточно выполнить части с тэгом `mode_vpn`:
```
ansible-playbook vpn.yml -t mode_vpn
```
После выполнения playbook все необходимые настройки применены.
Замеряем скорость.
На client выполнено:
```
TAP
root@client:~# iperf3 -c 10.10.10.1 -t 40 -i 5
Connecting to host 10.10.10.1, port 5201
[  5] local 10.10.10.2 port 54466 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-5.00   sec  45.8 MBytes  76.8 Mbits/sec   93    223 KBytes
[  5]   5.00-10.00  sec  32.7 MBytes  54.9 Mbits/sec    0    308 KBytes
[  5]  10.00-15.00  sec  33.5 MBytes  56.1 Mbits/sec  294    144 KBytes
[  5]  15.00-20.00  sec  40.6 MBytes  68.0 Mbits/sec   41    213 KBytes
[  5]  20.00-25.00  sec  38.4 MBytes  64.4 Mbits/sec   92    199 KBytes
^C[  5]  25.00-25.15  sec   759 KBytes  41.6 Mbits/sec    0    201 KBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-25.15  sec   192 MBytes  63.9 Mbits/sec  520             sender
[  5]   0.00-25.15  sec  0.00 Bytes  0.00 bits/sec                  receiver
iperf3: interrupt - the client has terminated
root@client:~#
```
На server выполнено:
```
root@server:~# iperf3 -s &
[2] 6120
root@server:~# iperf3: error - unable to start listener for connections: Address already in use
iperf3: exiting
Accepted connection from 10.10.10.2, port 54462
[  5] local 10.10.10.1 port 5201 connected to 10.10.10.2 port 54466
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-1.00   sec  12.5 MBytes   105 Mbits/sec
[  5]   1.00-2.00   sec  11.4 MBytes  95.8 Mbits/sec
[  5]   2.00-3.00   sec  6.72 MBytes  56.4 Mbits/sec
[  5]   3.00-4.00   sec  6.79 MBytes  56.9 Mbits/sec
[  5]   4.00-5.00   sec  6.74 MBytes  56.5 Mbits/sec
[  5]   5.00-6.00   sec  6.71 MBytes  56.3 Mbits/sec
[  5]   6.00-7.00   sec  6.71 MBytes  56.3 Mbits/sec
[  5]   7.00-8.00   sec  6.16 MBytes  51.6 Mbits/sec
[  5]   8.00-9.00   sec  6.78 MBytes  56.9 Mbits/sec
[  5]   9.00-10.00  sec  6.01 MBytes  50.4 Mbits/sec
[  5]  10.00-11.00  sec  6.70 MBytes  56.2 Mbits/sec
[  5]  11.00-12.00  sec  6.74 MBytes  56.6 Mbits/sec
[  5]  12.00-13.00  sec  6.12 MBytes  51.3 Mbits/sec
[  5]  13.00-14.00  sec  6.69 MBytes  56.1 Mbits/sec
[  5]  14.00-15.00  sec  7.03 MBytes  59.0 Mbits/sec
[  5]  15.00-16.00  sec  6.28 MBytes  52.7 Mbits/sec
[  5]  16.00-17.00  sec  5.83 MBytes  48.9 Mbits/sec
[  5]  17.00-18.00  sec  5.06 MBytes  42.4 Mbits/sec
[  5]  18.00-19.00  sec  6.14 MBytes  51.5 Mbits/sec
[  5]  19.00-20.00  sec  14.8 MBytes   124 Mbits/sec
[  5]  20.00-21.00  sec  15.6 MBytes   131 Mbits/sec
[  5]  21.00-22.00  sec  6.89 MBytes  57.8 Mbits/sec
[  5]  22.00-23.00  sec  6.68 MBytes  56.1 Mbits/sec
[  5]  23.00-24.00  sec  5.74 MBytes  48.1 Mbits/sec
[  5]  24.00-25.00  sec  6.21 MBytes  52.1 Mbits/sec
[  5]  24.00-25.00  sec  6.21 MBytes  52.1 Mbits/sec
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-25.00  sec   191 MBytes  64.1 Mbits/sec                  receiver
iperf3: the client has terminated
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
^C
[2]+  Exit 1                  iperf3 -s
```
Режимы tun и tap реализовывают туннель на разных уровенях сетевого взаимодействия:
tap - канальный уровень (кадры ethernet);
tun - сетевой уровень (ip пакеты).
На текущем стенде tun показал чуть более высокий результат по скорости и пропускной способности, соответственно.
Так как стенд развернут на виртуальных машинах, полагаю, уровень абстракции на сетевом уровне работает быстрее.
При реализации на физических устройствах уровень tap может оказаться более эффективным.

### 4. Поднять RAS на базе OpenVPN.

На вм ras выполнены настройки:
```
sudo -i
apt update -y
apt install openvpn -y
apt install easy-rsa -y
cd /etc/openvpn
/usr/share/easy-rsa/easyrsa init-pki
/usr/share/easy-rsa/easyrsa build-ca
/usr/share/easy-rsa/easyrsa gen-dh
openvpn --genkey secret ca.key
echo 'rasvpn' | /usr/share/easy-rsa/easyrsa gen-req server nopass
echo 'yes' | /usr/share/easy-rsa/easyrsa sign-req server server
echo 'client' | /usr/share/easy-rsa/easyrsa gen-req client nopass
echo 'yes' | /usr/share/easy-rsa/easyrsa sign-req client client
systemctl start openvpn@server
```
Содержание конфигурационных файлов следующее:
`cat /etc/openvpn/client/client`
```
ifconfig-push 10.10.10.2 255.255.255.0
iroute 10.10.10.0 255.255.255.0
```
`cat /etc/openvpn/server.conf`
```
port 1207 
proto udp 
dev tun 
ca /etc/openvpn/pki/ca.crt 
cert /etc/openvpn/pki/issued/server.crt 
key /etc/openvpn/pki/private/server.key 
dh /etc/openvpn/pki/dh.pem 
server 10.10.10.0 255.255.255.0 
ifconfig-pool-persist ipp.txt 
client-to-client 
client-config-dir /etc/openvpn/client 
keepalive 10 120 
comp-lzo 
persist-key 
persist-tun 
status /var/log/openvpn-status.log 
log /var/log/openvpn.log 
verb 3
local 192.168.56.30
topology subnet
ifconfig 10.10.10.1 255.255.255.0
```
Конфигурационный файл для клиента OpenVPN хостовой машины `client.ovpn`:
```
dev tun 
proto udp 
remote 192.168.56.30 1207 
client 
resolv-retry infinite 
remote-cert-tls server 
ca ./ca.crt 
cert ./client.crt 
key ./client.key
persist-key 
persist-tun 
comp-lzo 
verb 4
topology subnet
pull
```
Для успешного подключения в директорию с конфигурационным файлом клиента необходимо поместить файлы ca.crt, client.crt, client.key,
которые нужно скопировать с сервера:
```
/etc/openvpn/pki/ca.crt
/etc/openvpn/pki/issued/client.crt
/etc/openvpn/pki/private/client.key
```
С целью копирования файлов можно запустить PLAY `Configure vpn ras` в `vpn.yml`.
Результаты после подключения:

полученный ip-адрес
```
PS C:\Users\Sof> ipconfig
Неизвестный адаптер OpenVPN TAP-Windows6:

   DNS-суффикс подключения . . . . . :
   Локальный IPv6-адрес канала . . . : fe80::8345:b08a:d690:4d15%3
   IPv4-адрес. . . . . . . . . . . . : 10.10.10.2
   Маска подсети . . . . . . . . . . : 255.255.255.0
   Основной шлюз. . . . . . . . . :

```
таблица маршрутизации
```
PS C:\Users\Sof> route print
IPv4 таблица маршрута
===========================================================================
Активные маршруты:
Сетевой адрес           Маска сети      Адрес шлюза       Интерфейс  Метрика
       10.10.10.0    255.255.255.0         On-link        10.10.10.2    281
       10.10.10.2  255.255.255.255         On-link        10.10.10.2    281
     10.10.10.255  255.255.255.255         On-link        10.10.10.2    281
```
сетевая связность с клиента
```
PS C:\Users\Sof> ping 10.10.10.1

Обмен пакетами с 10.10.10.1 по с 32 байтами данных:
Ответ от 10.10.10.1: число байт=32 время<1мс TTL=64
Ответ от 10.10.10.1: число байт=32 время=1мс TTL=64
Ответ от 10.10.10.1: число байт=32 время<1мс TTL=64
Ответ от 10.10.10.1: число байт=32 время<1мс TTL=64

```
сетевая связность с сервера
```
vagrant@ras:~$ ping 10.10.10.2
PING 10.10.10.2 (10.10.10.2) 56(84) bytes of data.
64 bytes from 10.10.10.2: icmp_seq=1 ttl=128 time=0.672 ms
64 bytes from 10.10.10.2: icmp_seq=2 ttl=128 time=4.79 ms
64 bytes from 10.10.10.2: icmp_seq=3 ttl=128 time=2.96 ms
```