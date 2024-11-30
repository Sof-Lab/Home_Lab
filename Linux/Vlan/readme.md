# Vagrant-Ansible стeнд с VLAN и LACP

## Описание задачи

в Office1 в тестовой подсети появляется сервера с доп интерфейсами и адресами
в internal сети testLAN:

testClient1 - 10.10.10.254
testClient2 - 10.10.10.254
testServer1- 10.10.10.1
testServer2- 10.10.10.1

Равести вланами:
testClient1 <-> testServer1
testClient2 <-> testServer2

Между centralRouter и inetRouter "пробросить" 2 линка (общая inernal сеть) и объединить их в бонд, проверить работу c отключением интерфейсов.

## Выполнение

*Лабораторный стенд развёрнут на хосте с Windows + WSL2. На Windows установлены Vagrant и VirtualBox. Ansible установлен на WSL.*

*Все файлы для vagrant располагаются в директории windows (win_directory), у меня это - D:\VBox_Projects\vlan\. Команды для работы с vagrant запускаются из той же директории.*

*Все файлы для ansible располагаются в директории wsl (wsl_directory), у меня это - /home/sof/sof/otus_labs/vlan/. Команды для работы с ansible звпускаются из той же директории.*

### 1. Разворачивание стенда при помощи Vagrant.

Создан Vagrantfile *(win_directory)* для разворачивания лабороторного стенда.
Ниже представлена схема стенда:

![Image alt](https://github.com/Sof-Lab/Home_Lab/blob/main/Linux/Vlan/Схема.png)

Для доступа к вм из wsl в Vagrantfile прописан дополнительный проброс порта `ssh-for-wsl` для каждой вм.
В нём нужно указать ip-адрес хоста и желаемый порт ssh для подключения для каждой вм:

```
        :wsl =>	[{auto_correct: true, guest: 22, host: 'указать порт для подключения по ssh', host_ip: "указать ip-адрес хоста", id: "ssh-for-wsl"}],
```

### 2. Настройка ВМ при помощи Ansible.

В файле staging/hosts.yaml *(wsl_directory)* нужно заполнить переменные для выполнения настройки стенда.
Для подключения к ВМ:
```
    host_ip: 192.168.1.8 # windows host ip
    dir_wsl: /home/sof/otus_labs/vlan/ # directory wsl whith ansible files
    dir_vagrant: /mnt/d/VBox_Projects/vlan/ # directory wsl whith vagrant files
	
	ansible_port: 'указать порт для подключения по ssh' # указывается к каждой вм согласно настройкам в Vagrantfile ":wsl"
```
В файле staging/hosts.yaml *(wsl_directory)* дополнительно прописан localhost для выполнения команд в wsl.
Это требуется, чтобы скопировать ключ private_key для подключения к ВМ из директории windows в директорию wsl.

В `vlan.yml` PLAY `WSL localhost copy private_key` копирует private_key на wsl.

PLAY `Base Configure Hosts RedHat` и `Base Configure Hosts Debian` устанавливает необходимые для дальнейшей работы пакеты.

### 3. Настройка VLAN при помощи Ansible.

PLAY `Configure VLAN 1` и `Configure VLAN 2` осуществляют настройку: добавляет на вм конфигурационные файлы интерфейсов и применяют настройки.
Конфигурационный файл берется из шаблона, который берет переменные из staging/hosts.yaml *(wsl_directory)*:
```
vlan_id: 'указать vid для интерфейса на хосте'
vlan_ip: 'указать ip для интерфейса на хосте'
```

Проверим конфигурацию интерфейсов до выполнения вышеописанных настроек на testClient1:
```
[root@testClient1 ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:50:91:89 brd ff:ff:ff:ff:ff:ff
    altname enp0s3
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute eth0
       valid_lft 80827sec preferred_lft 80827sec
    inet6 fe80::a00:27ff:fe50:9189/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:81:55:2d brd ff:ff:ff:ff:ff:ff
    altname enp0s8
    inet6 fe80::4463:98c7:9527:74f4/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
```
Проверим конфигурацию интерфейсов после выполнения вышеописанных настроек на testClient1:
```
[root@testClient1 ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:50:91:89 brd ff:ff:ff:ff:ff:ff
    altname enp0s3
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute eth0
       valid_lft 86374sec preferred_lft 86374sec
    inet6 fe80::a00:27ff:fe50:9189/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:81:55:2d brd ff:ff:ff:ff:ff:ff
    altname enp0s8
    inet6 fe80::4463:98c7:9527:74f4/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
4: eth1.1@eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 08:00:27:81:55:2d brd ff:ff:ff:ff:ff:ff
    inet 10.10.10.254/24 brd 10.10.10.255 scope global noprefixroute eth1.1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe81:552d/64 scope link
       valid_lft forever preferred_lft forever
```
В рзультате добавился виртуальный интерфейс 4 eth1.1@eth1 с заданным ip.
Проверим доступ по сети до хоста, который находится с ним в одном VLAN (до testServer1):
```
[root@testClient1 ~]# ping 10.10.10.254
PING 10.10.10.254 (10.10.10.254) 56(84) bytes of data.
64 bytes from 10.10.10.254: icmp_seq=1 ttl=64 time=0.259 ms
64 bytes from 10.10.10.254: icmp_seq=2 ttl=64 time=0.040 ms
64 bytes from 10.10.10.254: icmp_seq=3 ttl=64 time=0.021 ms
64 bytes from 10.10.10.254: icmp_seq=4 ttl=64 time=0.052 ms
^C
--- 10.10.10.254 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3095ms
rtt min/avg/max/mdev = 0.021/0.093/0.259/0.096 ms
```
Сеть доступна.

### 4. Настройка LACP при помощи Ansible.

PLAY `Configure LACP` осуществляют настройку: добавляет на вм конфигурационные файлы интерфейсов и применяют настройки.
Конфигурационный файл берется из шаблона, который берет переменные из staging/hosts.yaml *(wsl_directory)*:
```
bond_ip: 'указать ip для интерфейса на хосте'
```
После выполнения запустим пинг от inetRouter до centralRouter:
```
[root@inetRouter ~]# ping 192.168.255.2
PING 192.168.255.2 (192.168.255.2) 56(84) bytes of data.
64 bytes from 192.168.255.2: icmp_seq=1 ttl=64 time=1.70 ms
64 bytes from 192.168.255.2: icmp_seq=2 ttl=64 time=0.636 ms
64 bytes from 192.168.255.2: icmp_seq=3 ttl=64 time=0.454 ms
64 bytes from 192.168.255.2: icmp_seq=4 ttl=64 time=0.556 ms
```
Пинг проходит.
Причем, если отключить на centralRouter интерфейс eth1:
```
[root@centralRouter ~]# ip link set down eth1
```
пинги не прерываются.
Так выглядит конфигурация интерфейсов на inetRouter:
```
[root@inetRouter ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:50:91:89 brd ff:ff:ff:ff:ff:ff
    altname enp0s3
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute eth0
       valid_lft 76417sec preferred_lft 76417sec
    inet6 fe80::a00:27ff:fe50:9189/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc fq_codel master bond0 state UP group default qlen 1000
    link/ether 08:00:27:7a:87:99 brd ff:ff:ff:ff:ff:ff
    altname enp0s8
4: eth2: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc fq_codel master bond0 state UP group default qlen 1000
    link/ether 08:00:27:9e:ce:8e brd ff:ff:ff:ff:ff:ff
    altname enp0s9
5: bond0: <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 08:00:27:7a:87:99 brd ff:ff:ff:ff:ff:ff
    inet 192.168.255.1/30 brd 192.168.255.3 scope global noprefixroute bond0
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe7a:8799/64 scope link
       valid_lft forever preferred_lft forever
```