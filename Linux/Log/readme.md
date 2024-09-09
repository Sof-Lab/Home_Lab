# Vagrant-стенд c Rsyslog

## Описание задачи

1. В Vagrant разворачиваем 2 виртуальные машины web и log
2. на web настраиваем nginx
3. на log настраиваем центральный лог сервер на rsyslog

Все критичные логи с web должны собираться и локально и удаленно.
Все логи с nginx должны уходить на удаленный сервер (локально только критичные).


## Выполнение

*Лабораторный стенд развёрнут на хосте с Windows + WSL2. На Windows установлены Vagrant и VirtualBox. Ansible установлен на WSL.*

*Все файлы для vagrant располагаются в директории windows (win_directory), у меня это - D:\VBox_Projects\log\. Команды для работы с vagrant запускаются из той же директории.*

*Все файлы для ansible располагаются в директории wsl (wsl_directory), у меня это - /home/sof/sof/otus_labs/log/. Команды для работы с ansible звпускаются из той же директории.*

### 1. Запуск ВМ с помощью vagrant.

Для доступа к ВМ из wsl в Vagrantfile прописан дополнительный проброс порта `ssh-for-wsl`.
В нём нужно указать ip-адрес хоста и желаемый порт ssh для подключения:
```
:wslp => "", # Порт для подключения по ssh из WSL
:hostip => "192.168.1.8", #  # Ip-адрес Windows-хоста.
```
		  
### 2. Настройка ВМ с помощью ansible.

В файле staging/hosts.yaml нужно заполнить переменные для выполнения настройки ВМ:

```
all:
  vars:
    host_ip: 192.168.1.8						# Ip-адрес Windows-хоста
    dir_wsl: /home/sof/otus_labs/log/ 			# Директория wsl, где расположены файлы ansible
    dir_vagrant: /mnt/d/VBox_Projects/log/ 		# Директория wsl, где расположены файлы windows-хоста для работы с vagrant

    vm_name:									# имя ВМ в VB
    vm_port:									# Порт для подключения по ssh
```

В файле staging/hosts.yaml прописан localhost для выполнения команд в wsl.
Это требуется, чтобы скопировать ключ private_key для подключения к ВМ из директории windows в директорию wsl.

Запуск Playbook pam.yml.

```console
~/otus_labs/log$ ansible-playbook log.yml

PLAY [WSL localhost copy private_key] ***************************************************************************************

TASK [Gathering Facts] ******************************************************************************************************
ok: [wsl]

TASK [Create directory for private_key] *************************************************************************************
changed: [wsl] => (item=/home/sof/otus_labs/log/certs/web)
changed: [wsl] => (item=/home/sof/otus_labs/log/certs/log)

TASK [Copy private_key file] ************************************************************************************************
changed: [wsl] => (item={'src': '/mnt/d/VBox_Projects/log//.vagrant/machines/web/virtualbox/private_key', 'dst': '/home/sof/otus_labs/log/certs/web/private_key'})
changed: [wsl] => (item={'src': '/mnt/d/VBox_Projects/log//.vagrant/machines/log/virtualbox/private_key', 'dst': '/home/sof/otus_labs/log/certs/log/private_key'})

TASK [Change permissions for private_key] ***********************************************************************************
changed: [wsl] => (item=/home/sof/otus_labs/log/certs/web/private_key)
changed: [wsl] => (item=/home/sof/otus_labs/log/certs/log/private_key)

PLAY [Configure vbox_vm] ****************************************************************************************************

TASK [Gathering Facts] ******************************************************************************************************
ok: [log]
ok: [web]

TASK [Set timezone] *********************************************************************************************************
changed: [log]
changed: [web]

TASK [Install chrony] *******************************************************************************************************
changed: [web]
changed: [log]

TASK [Update all] ***********************************************************************************************************
ok: [web]
ok: [log]

PLAY [Configure web] ********************************************************************************************************

TASK [Gathering Facts] ******************************************************************************************************
ok: [web]

TASK [Install nginx] ********************************************************************************************************
changed: [web]

TASK [Config files] *********************************************************************************************************
changed: [web] => (item={'src': 'templates/nginx.conf.j2', 'dst': '/etc/nginx/nginx.conf'})
changed: [web] => (item={'src': 'templates/crit.conf.j2', 'dst': '/etc/rsyslog.d/crit.conf'})
changed: [web] => (item={'src': 'templates/audit.conf.j2', 'dst': '/etc/rsyslog.d/audit.conf'})

TASK [Restart nginx] ********************************************************************************************************
changed: [web]

PLAY [Configure log] ********************************************************************************************************

TASK [Gathering Facts] ******************************************************************************************************
ok: [log]

TASK [Config rsyslog] *******************************************************************************************************
changed: [log]

TASK [Change permissions for log directory] *********************************************************************************
ok: [log]

TASK [Restart rsyslog] ******************************************************************************************************
changed: [log]

PLAY [check result web] *****************************************************************************************************

TASK [Gathering Facts] ******************************************************************************************************
ok: [web]

TASK [Check time synh] ******************************************************************************************************
changed: [web]

TASK [debug] ****************************************************************************************************************
ok: [web] => {
    "msg": [
        "               Local time: Mon 2024-09-09 04:05:52 MSK",
        "           Universal time: Mon 2024-09-09 01:05:52 UTC",
        "                 RTC time: Mon 2024-09-09 01:05:51",
        "                Time zone: Europe/Moscow (MSK, +0300)",
        "System clock synchronized: yes",
        "              NTP service: active",
        "          RTC in local TZ: no"
    ]
}

TASK [Check status nginx] ***************************************************************************************************
changed: [web]

TASK [debug] ****************************************************************************************************************
ok: [web] => {
    "msg": [
        "● nginx.service - A high performance web server and a reverse proxy server",
        "     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: enabled)",
        "     Active: active (running) since Mon 2024-09-09 04:05:47 MSK; 4s ago",
        "       Docs: man:nginx(8)",
        "    Process: 3548 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)",
        "    Process: 3549 ExecStart=/usr/sbin/nginx -g daemon on; master_process on; (code=exited, status=0/SUCCESS)",
        "   Main PID: 3551 (nginx)",
        "      Tasks: 3 (limit: 1641)",
        "     Memory: 2.3M (peak: 2.5M)",
        "        CPU: 14ms",
        "     CGroup: /system.slice/nginx.service",
        "             ├─3551 \"nginx: master process /usr/sbin/nginx -g daemon on; master_process on;\"",
        "             ├─3552 \"nginx: worker process\"",
        "             └─3553 \"nginx: worker process\"",
        "",
        "Sep 09 04:05:47 web systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...",
        "Sep 09 04:05:47 web systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server."
    ]
}

TASK [Check ports nginx] ****************************************************************************************************
changed: [web]

TASK [debug] ****************************************************************************************************************
ok: [web] => {
    "msg": [
        "LISTEN 0      511          0.0.0.0:80        0.0.0.0:*          ",
        "LISTEN 0      511             [::]:80           [::]:*          "
    ]
}

TASK [Check http code] ******************************************************************************************************
ok: [web]

TASK [Break nginx step 1] ***************************************************************************************************
changed: [web]

TASK [Break nginx step 2] ***************************************************************************************************
changed: [web]

TASK [Check http code after break] ******************************************************************************************
ok: [web]

TASK [Fix nginx] ************************************************************************************************************
changed: [web]

PLAY [check result log] *****************************************************************************************************

TASK [Gathering Facts] ******************************************************************************************************
ok: [log]

TASK [Check time synh] ******************************************************************************************************
changed: [log]

TASK [debug] ****************************************************************************************************************
ok: [log] => {
    "msg": [
        "               Local time: Mon 2024-09-09 04:05:56 MSK",
        "           Universal time: Mon 2024-09-09 01:05:56 UTC",
        "                 RTC time: Mon 2024-09-09 01:05:56",
        "                Time zone: Europe/Moscow (MSK, +0300)",
        "System clock synchronized: yes",
        "              NTP service: active",
        "          RTC in local TZ: no"
    ]
}

TASK [Check ports rsyslog] **************************************************************************************************
changed: [log]

TASK [debug] ****************************************************************************************************************
ok: [log] => {
    "msg": [
        "udp   UNCONN 0      0             0.0.0.0:514       0.0.0.0:*          ",
        "udp   UNCONN 0      0                [::]:514          [::]:*          ",
        "tcp   LISTEN 0      25            0.0.0.0:514       0.0.0.0:*          ",
        "tcp   LISTEN 0      25               [::]:514          [::]:*          "
    ]
}

TASK [Check http code] ******************************************************************************************************
ok: [log]

TASK [Check log directorys] *************************************************************************************************
changed: [log]

TASK [debug] ****************************************************************************************************************
ok: [log] => {
    "msg": [
        "log",
        "web"
    ]
}

PLAY RECAP ******************************************************************************************************************
log                        : ok=16   changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
web                        : ok=20   changed=11   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
wsl                        : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### 3. Проверка результатов.

Проверка логов от nginx:

```console
root@log:~# ls /var/log/rsyslog/web/
nginx_access.log  nginx_error.log

root@log:~# cat /var/log/rsyslog/web/nginx_access.log
2024-09-09T04:05:53+03:00 web nginx_access: 192.168.56.10 - - [09/Sep/2024:04:05:53 +0300] "GET / HTTP/1.1" 200 615 "-" "ansible-httpget"
2024-09-09T04:05:54+03:00 web nginx_access: 192.168.56.10 - - [09/Sep/2024:04:05:54 +0300] "GET / HTTP/1.1" 403 162 "-" "ansible-httpget"
2024-09-09T04:05:57+03:00 web nginx_access: 192.168.56.15 - - [09/Sep/2024:04:05:57 +0300] "GET / HTTP/1.1" 200 615 "-" "ansible-httpget"

root@log:~# cat /var/log/rsyslog/web/nginx_error.log
2024-09-09T04:05:54+03:00 web nginx_error: 2024/09/09 04:05:54 [error] 3552#3552: *2 directory index of "/var/www/html/" is forbidden, client: 192.168.56.10, server: _, request: "GET / HTTP/1.1", host: "192.168.56.10"
```

Проверка наличия различных логов после ребута web:

```console
root@log:~# ls /var/log/rsyslog/web/
 apparmor.systemd.log   ModemManager.log          snapd-apparmor.log   systemd-logind.log         udisksd.log
 chronyd.log            multipathd.log            snapd.log            systemd-modules-load.log   vboxadd.log
'(cron).log'            networkd-dispatcher.log   sshd.log             systemd-networkd.log       vboxadd-service.log
 cron.log               nginx_access.log          sudo.log             systemd-resolved.log       vboxadd-service.sh.log
 dbus-daemon.log        nginx_error.log           systemd-fsck.log     systemd-udevd.log
 kernel.log             polkitd.log              '(systemd).log'       tag_auth_log.log
 lvm.log                rsyslogd.log              systemd.log         '(udev-worker).log'
```

Успешно.