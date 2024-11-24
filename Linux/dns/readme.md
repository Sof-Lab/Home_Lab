# Vagrant-Ansible стeнд c DNS

## Описание задачи

1. Настроить dns:
- взять стенд https://github.com/erlong15/vagrant-bind;
- добавить еще один сервер client2;
- завести в зоне dns.lab имена: web1 - смотрит на клиент1, web2  смотрит на клиент2;
- завести еще одну зону newdns.lab и завести в ней запись;
- www - смотрит на обоих клиентов.

2. Настроить split-dns:
- клиент1 - видит обе зоны, но в зоне dns.lab только web1;
- клиент2 видит только dns.lab.


## Выполнение

*Лабораторный стенд развёрнут на хосте с Windows + WSL2. На Windows установлены Vagrant и VirtualBox. Ansible установлен на WSL.*

*Все файлы для vagrant располагаются в директории windows (win_directory), у меня это - D:\VBox_Projects\dns\. Команды для работы с vagrant запускаются из той же директории.*

*Все файлы для ansible располагаются в директории wsl (wsl_directory), у меня это - /home/sof/sof/otus_labs/dns/. Команды для работы с ansible звпускаются из той же директории.*

### 1. Настройка

Скачен подготовленный стенд с https://github.com/erlong15/vagrant-bind:
`git clone https://github.com/erlong15/vagrant-bind.git`

В Vagrantfile *(win_directory)* добавлена ВМ client2.

Для доступа к вм из wsl в Vagrantfile прописан дополнительный проброс порта `ssh-for-wsl` для каждой вм.
В нём нужно указать ip-адрес хоста и желаемый порт ssh для подключения для каждой вм:

```
config.vm.network "forwarded_port", auto_correct: true, guest: 22, host: opts[:wsl], host_ip: "указать ip-адрес хоста", id: "ssh-for-wsl"
```

Дальнейшее выполнение осуществляется при помощи Ansible.

В файле staging/hosts.yaml *(wsl_directory)* нужно заполнить переменные для выполнения настройки стенда.
Для подключения к ВМ:
```
    host_ip: 192.168.1.8 # windows host ip
    dir_wsl: /home/sof/otus_labs/dns/ # directory wsl whith ansible files
    dir_vagrant: /mnt/d/VBox_Projects/dns/ # directory wsl whith vagrant files
	
	ansible_port: 'указать порт для подключения по ssh' # указывается к каждой вм согласно настройкам в Vagrantfile ":wsl"
```
В файле staging/hosts.yaml *(wsl_directory)* дополнительно прописан localhost для выполнения команд в wsl.
Это требуется, чтобы скопировать ключ private_key для подключения к ВМ из директории windows в директорию wsl.

В `playbook.yml` *(wsl_directory)* добавлен первый TASK (выполняется на `hosts: wsl`), который копирует private_key на wsl.
Далее TASK (выполняется на `hosts: dns`) осуществляется первичная настройка стенда (установка пакетов, настройка синхронизации времени и тд).

Для настройки dns с заданными требованиями скорректированы файлы *(wsl_directory)*:
- servers-resolv.conf -> servers-resolv.conf.j2 (прописаны соответствующие ip-адреса для ns01 и ns02 хостов);
- named.dns.lab (добавлены имена web1 и web2)
- master-named.conf и slave-named.conf (добавлена зона newdns.lab);
- создан named.newdns.lab (добавление записей www в зону newdns.lab).

Для настройки split-dns с заданными требованиями сгенерированы ключи:

```
[root@ns01 ~]# tsig-keygen client
key "client" {
        algorithm hmac-sha256;
        secret "hdmLvbSS3SV41ysDNcN7p2Nunn78Baqa1mAqf10lns8=";
};


[root@ns01 ~]# tsig-keygen client2
key "client2" {
        algorithm hmac-sha256;
        secret "ky0oktpti0BLPBJLUeD4rJgUHALFOMERVVS/PV+v5w0=";
};


[root@ns01 ~]# tsig-keygen -a hmac-md5 rndc-key
key "rndc-key" {
        algorithm hmac-md5;
        secret "1VJEYrd+c2as1ppIb5q8/g==";
};
```

Далее скорректированы файлы *(wsl_directory)*:
- создан named.dns.lab.client (добавлена запись только web1);
- master-named.conf и slave-named.conf (добавлены сгенерированные ключи и accsess лист, описано представление view);
- rndc.conf (добавлен сгенерированный ключ).

В `playbook.yml` *(wsl_directory)* TASKs (выполняются на `hosts: ns01`, `hosts: ns02`, `hosts: client,client2`) осуществляют настройку стенда.

### 2. Проверка

После запуска `ansible-playbook playbook.yml` выполнена проверка:
```
[root@client ~]# dig @192.168.50.10 web1.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.16 <<>> @192.168.50.10 web1.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 8207
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web1.dns.lab.                  IN      A

;; ANSWER SECTION:
web1.dns.lab.           3600    IN      A       192.168.50.15

;; AUTHORITY SECTION:
dns.lab.                3600    IN      NS      ns02.dns.lab.
dns.lab.                3600    IN      NS      ns01.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.           3600    IN      A       192.168.50.10
ns02.dns.lab.           3600    IN      A       192.168.50.11

;; Query time: 1 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Sun Nov 24 20:58:58 MSK 2024
;; MSG SIZE  rcvd: 127
```
```
[root@client ~]# dig @192.168.50.11 web2.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.16 <<>> @192.168.50.11 web2.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 8516
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web2.dns.lab.                  IN      A

;; AUTHORITY SECTION:
.                       10800   IN      SOA     a.root-servers.net. nstld.verisign-grs.com. 2024112401 1800 900 604800 86400

;; Query time: 193 msec
;; SERVER: 192.168.50.11#53(192.168.50.11)
;; WHEN: Sun Nov 24 20:59:07 MSK 2024
;; MSG SIZE  rcvd: 116
```
В примерах выполнено обращение к разным DNS-серверам с разными запросами.
Проверка split на client:
```
[root@client ~]#  ping www.newdns.lab
PING www.newdns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from client (192.168.50.15): icmp_seq=1 ttl=64 time=0.007 ms
64 bytes from client (192.168.50.15): icmp_seq=2 ttl=64 time=0.091 ms
64 bytes from client (192.168.50.15): icmp_seq=3 ttl=64 time=0.059 ms
^C
--- www.newdns.lab ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2004ms
rtt min/avg/max/mdev = 0.007/0.052/0.091/0.035 ms
```
```
[root@client ~]# ping web1.dns.lab
PING web1.dns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from client (192.168.50.15): icmp_seq=1 ttl=64 time=0.008 ms
64 bytes from client (192.168.50.15): icmp_seq=2 ttl=64 time=0.047 ms
64 bytes from client (192.168.50.15): icmp_seq=3 ttl=64 time=0.056 ms
^C
--- web1.dns.lab ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 0.008/0.037/0.056/0.020 ms
```
```
[root@client ~]#  ping web2.dns.lab
ping: web2.dns.lab: Name or service not known
[root@client ~]#
```
Проверка split на client2:
```
[root@client2 ~]# ping www.newdns.lab
ping: www.newdns.lab: Name or service not known
```
```
[root@client2 ~]# ping web1.dns.lab
PING web1.dns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from 192.168.50.15 (192.168.50.15): icmp_seq=1 ttl=64 time=0.666 ms
64 bytes from 192.168.50.15 (192.168.50.15): icmp_seq=2 ttl=64 time=1.53 ms
64 bytes from 192.168.50.15 (192.168.50.15): icmp_seq=3 ttl=64 time=3.21 ms
^C
--- web1.dns.lab ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 0.666/1.802/3.211/1.057 ms
```
```
[root@client2 ~]# ping web2.dns.lab
PING web2.dns.lab (192.168.50.16) 56(84) bytes of data.
64 bytes from client2 (192.168.50.16): icmp_seq=1 ttl=64 time=0.017 ms
64 bytes from client2 (192.168.50.16): icmp_seq=2 ttl=64 time=0.034 ms
64 bytes from client2 (192.168.50.16): icmp_seq=3 ttl=64 time=0.055 ms
^C
--- web2.dns.lab ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
rtt min/avg/max/mdev = 0.017/0.035/0.055/0.016 ms
[root@client2 ~]#
```
Проверка кофигурационного файла named:`named-checkconf /etc/named.conf`.