# Vagrant стeнд для работы с NFS

## Описание задачи

Vagrant up должен поднимать 2 виртуалки: сервер и клиент;
на сервер должна быть расшарена директория;
на клиента она должна автоматически монтироваться при старте (fstab или autofs);
в шаре должна быть папка upload с правами на запись;
требования для NFS: NFSv3 по UDP, включенный firewall.

1. Запустить 2 виртуалки: сервер и клиент.
2. Выполнить проверку.

## Выполнение

### 1. Запуск ВМ.

Подготовлен автоматизированный Vagrantfile, где применяютя все необходимые настройки.
Командой vagrant up поднимаются требуемые ВМ.

### 2. Проверка результатов.

Проверка и на сервере, и на клиенте, что firewall запущен:
```console
sudo -i
systemctl status ufw
```
```
root@nfss:~# systemctl status ufw
● ufw.service - Uncomplicated firewall
   Loaded: loaded (/lib/systemd/system/ufw.service; enabled; vendor preset: enabled)
   Active: active (exited) since Sun 2024-08-04 11:29:18 UTC; 49min ago
  Process: 367 ExecStart=/lib/ufw/ufw-init start quiet (code=exited, status=0/SUCCESS)
 Main PID: 367 (code=exited, status=0/SUCCESS)
    Tasks: 0
   Memory: 0B
      CPU: 0
   CGroup: /system.slice/ufw.service

Warning: Journal has been rotated since unit was started. Log output is incomplete or unavailable.
```
```
root@nfsc:~# systemctl status ufw
● ufw.service - Uncomplicated firewall
   Loaded: loaded (/lib/systemd/system/ufw.service; enabled; vendor preset: enabled)
   Active: active (exited) since Sun 2024-08-04 11:30:20 UTC; 48min ago
  Process: 362 ExecStart=/lib/ufw/ufw-init start quiet (code=exited, status=0/SUCCESS)
 Main PID: 362 (code=exited, status=0/SUCCESS)
    Tasks: 0
   Memory: 0B
      CPU: 0
   CGroup: /system.slice/ufw.service

Warning: Journal has been rotated since unit was started. Log output is incomplete or unavailable.
```
Проверка работы RPC на сервере NFS:
```console
root@nfss:~# showmount -a 192.168.50.10
All mount points on 192.168.50.10:
192.168.50.11:/srv/share
```
Проверка работы RPC на книенте NFS:
```console
root@nfsc:~# showmount -a 192.168.50.10
All mount points on 192.168.50.10:
192.168.50.11:/srv/share
```
Проверяем экспорты на сервере NFS:
```console
root@nfss:~# exportfs
/srv/share      192.168.50.11/32
```
Проверяем статус монтирования на клиенте NFS:
```console
root@nfsc:~# mount | grep /mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=27,pgrp=1,timeout=0,minproto=5,maxproto=5,direct)
192.168.50.10:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=44057,mountproto=udp,local_lock=none,addr=192.168.50.10)
```
По выводу видно, что используется nfs версии 3 по протоколу udp.
Создаем дополнительные файлы для проверки на сервере и клиенте:
```console
root@nfss:~# touch /srv/share/upload/server_file2
root@nfsc:~# touch /mnt/upload/client_file2
```
Проверка наличия файлов:
```console
root@nfss:~# ls -l /srv/share/upload/
total 0
-rw-r--r-- 1 nobody nogroup 0 Aug  4 11:30 client_file
-rw-r--r-- 1 nobody nogroup 0 Aug  4 12:13 client_file2
-rw-r--r-- 1 root   root    0 Aug  4 11:28 server_file
-rw-r--r-- 1 root   root    0 Aug  4 12:12 server_file2
```
```console
root@nfsc:~# ls -l /mnt/upload/
total 0
-rw-r--r-- 1 nobody nogroup 0 Aug  4 11:30 client_file
-rw-r--r-- 1 nobody nogroup 0 Aug  4 12:13 client_file2
-rw-r--r-- 1 root   root    0 Aug  4 11:28 server_file
-rw-r--r-- 1 root   root    0 Aug  4 12:12 server_file2
```
Успешно отображаются файлы, созданные при настройке, а также файлы, созданные уже после ребута для финальной проверки.