# Работа с selinux часть 2.

## Описание задачи

1. Поднять подготовленный стенд с помощью Vagrant и Ansible.
2. Выяснить причину неработоспособности механизма обновления зоны. Решить проблему.

*Лабораторный стенд развёрнут на хосте с Windows + WSL2. На Windows установлены Vagrant и VirtualBox. Ansible установлен на WSL.*

*Все файлы для vagrant располагаются в директории windows, у меня это - D:\VBox_Projects\selinux2. Команды для работы с vagrant запускаются из той же директории.*

*Все файлы для ansible располагаются в директории wsl, у меня это - /home/sof/otus_labs/selinux. Команды для работы с ansible звпускаются из той же директории.*

## Выполнение

### 1. Поднять подготовленный стенд с помощью Vagrant и Ansible.

Запущена ВМ при помощи Vagrantfile.
Запущен playbook при помощи Ansible.

Попробуем внести изменения в зону с вм client:

```console
nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
> quit
```
Изменения внести не получилось.

### 2. Выяснить причину неработоспособности механизма обновления зоны. Решить проблему.

Поиск ошибки по логам:
```console
cat /var/log/audit/audit.log | audit2why
```
На client вывод пустой.
На ns01:
```
type=AVC msg=audit(1718049996.937:2031): avc:  denied  { create } for  pid=5320 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0

        Was caused by:
                Missing type enforcement (TE) allow rule.

                You can use audit2allow to generate a loadable module to allow this access.
```
*Такой же вывод дает команда audit2allow -w -a*
Дополнительно можно посмотреть:
```console
audit2allow -a
```
```
#============= named_t ==============

#!!!! WARNING: 'etc_t' is a base type.
allow named_t etc_t:file create;
```
Ошибка в контексте безопасности. Вместо типа named_t используется тип etc_t.
Проверим данную проблему в каталоге /etc/named:
```console
ls -laZ /etc/named
```
```
drw-rwx---. root named system_u:object_r:etc_t:s0       .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:etc_t:s0   dynamic
-rw-rw----. root named system_u:object_r:etc_t:s0       named.50.168.192.rev
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab
-rw-rw----. root named system_u:object_r:etc_t:s0       named.dns.lab.view1
-rw-rw----. root named system_u:object_r:etc_t:s0       named.newdns.lab
```
Изменим тип контекста безопасности для каталога /etc/named:
```console
sudo chcon -R -t named_zone_t /etc/named
ls -laZ /etc/named
```
```
drw-rwx---. root named system_u:object_r:named_zone_t:s0 .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:named_zone_t:s0 dynamic
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.50.168.192.rev
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab.view1
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.newdns.lab
```
Теперь на вм client:
```console
nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
> quit

dig www.ddns.lab
```
```
; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.15 <<>> www.ddns.lab
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 9989
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.ddns.lab.                  IN      A

;; ANSWER SECTION:
www.ddns.lab.           60      IN      A       192.168.50.15

;; AUTHORITY SECTION:
ddns.lab.               3600    IN      NS      ns01.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.           3600    IN      A       192.168.50.10

;; Query time: 2 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Mon Jun 10 20:52:23 UTC 2024
;; MSG SIZE  rcvd: 96
```