# Работа с selinux часть 1.

## Описание задачи

1. Создать ВМ с помощью Vgarnt с установленным nginx, работающим на нестандартном порту, и включенным selinux.
2. Запустить nginx на нестандартном порту 3-мя разными способами:
2.1. переключатели setsebool;
2.2. добавление нестандартного порта в имеющийся тип;
2.3. формирование и установка модуля SELinux.

## Выполнение

### 1. Создать ВМ с помощью Vgarnt с установленным nginx, работающим на нестандартном порту, и включенным selinux.

Скачен образ с centos/7-2004.01.
При помощи команды образ добавлен в Vagrant:
Запущена ВМ при помощи Vagrantfile.

### 2. Запустить nginx на нестандартном порту 3-мя разными способами.

Проверка статуса nginx:
```console
sudo -i
systemctl status nginx
```
```
 nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Mon 2024-06-10 17:07:31 UTC; 2min 34s ago
  Process: 2849 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
  Process: 2847 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)

Jun 10 17:07:31 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jun 10 17:07:31 selinux nginx[2849]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jun 10 17:07:31 selinux nginx[2849]: nginx: [emerg] bind() to 0.0.0.0:4881 failed (13: Permission denied)
Jun 10 17:07:31 selinux nginx[2849]: nginx: configuration file /etc/nginx/nginx.conf test failed
Jun 10 17:07:31 selinux systemd[1]: nginx.service: control process exited, code=exited status=1
Jun 10 17:07:31 selinux systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
Jun 10 17:07:31 selinux systemd[1]: Unit nginx.service entered failed state.
Jun 10 17:07:31 selinux systemd[1]: nginx.service failed.
```
Проверка статуса firewalld:
```console
systemctl status firewalld
```
```
systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
     Docs: man:firewalld(1)
```
Проверка конфигурации nginx:
```console
nginx -t
```
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```
Проверка режима selinux:
```console
getenforce
```
```
Enforcing
```

#### 2.1. Переключатели setsebool.

Находим в логах информацию о блокировании порта:
```console
cat /var/log/audit/audit.log
```
Смотрим при помощи утилиты audit2why:
```console
grep 1718039251.623:824 /var/log/audit/audit.log | audit2why
```
```
type=AVC msg=audit(1718039251.623:824): avc:  denied  { name_bind } for  pid=2849 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

        Was caused by:
        The boolean nis_enabled was set incorrectly.
        Description:
        Allow nis to enabled

        Allow access by executing:
        # setsebool -P nis_enabled 1
```
Включим параметр nis_enabled и перезапустим nginx:
```console
setsebool -P nis_enabled on
systemctl restart nginx
```
Проверка результата:
```console
systemctl status nginx
```
```
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Mon 2024-06-10 17:39:06 UTC; 5s ago
  Process: 3169 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 3165 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 3163 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 3172 (nginx)
   CGroup: /system.slice/nginx.service
           ├─3172 nginx: master process /usr/sbin/nginx
           ├─3173 nginx: worker process
           └─3174 nginx: worker process

Jun 10 17:39:06 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jun 10 17:39:06 selinux nginx[3165]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jun 10 17:39:06 selinux nginx[3165]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jun 10 17:39:06 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
```
```console
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:4881
```
```
200
```
Проверка статуса параметра:
```console
getsebool -a | grep nis_enabled
```
```
nis_enabled --> on
```
Выключаем nis_enabled:
```console
setsebool -P nis_enabled off
systemctl restart nginx
getsebool -a | grep nis_enabled
```
```
nis_enabled --> off
```

#### 2.2. Добавление нестандартного порта в имеющийся тип.

Поиск имеющегося типа, для http трафика:
```console
semanage port -l | grep http
```
```
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
```
Добавим порт в тип http_port_t
```console
semanage port -a -t http_port_t -p tcp 4881
semanage port -l | grep  http_port_t
```
```
http_port_t                    tcp      4881, 80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
```
Проверка работы nginx:
```console
systemctl restart nginx
systemctl status nginx
```
```
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Mon 2024-06-10 17:48:36 UTC; 3s ago
  Process: 3228 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 3226 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 3224 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 3230 (nginx)
   CGroup: /system.slice/nginx.service
           ├─3230 nginx: master process /usr/sbin/nginx
           ├─3231 nginx: worker process
           └─3232 nginx: worker process

Jun 10 17:48:36 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jun 10 17:48:36 selinux nginx[3226]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jun 10 17:48:36 selinux nginx[3226]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jun 10 17:48:36 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
```
```console
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:4881
```
```
200
```
Удаляем нестандартный порт:
```console
semanage port -d -t http_port_t -p tcp 4881
semanage port -l | grep  http_port_t
systemctl restart nginx
```

#### 2.3. Формирование и установка модуля SELinux.

Просмотр логов nginx:
```console
grep nginx /var/log/audit/audit.log
```
При помощи утилиты audit2allow создаем модуль для nginx, используя логи:
```console
grep nginx /var/log/audit/audit.log | audit2allow -M nginx
```
```
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i nginx.pp
```
Применить созданный модуль:
```console
semodule -i nginx.pp
```
Проверка результата:
```console
systemctl restart nginx
systemctl status nginx
```
```
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Mon 2024-06-10 18:08:07 UTC; 1s ago
  Process: 3317 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 3312 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 3310 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 3318 (nginx)
   CGroup: /system.slice/nginx.service
           ├─3318 nginx: master process /usr/sbin/nginx
           ├─3319 nginx: worker process
           └─3320 nginx: worker process

Jun 10 18:08:07 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jun 10 18:08:07 selinux nginx[3312]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jun 10 18:08:07 selinux nginx[3312]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jun 10 18:08:07 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
```
```console
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:4881
```
```
200
```
Просмотр установленных модулей "semodule -l", например:
```console
semodule -l | grep nginx
```
```
nginx   1.0
```
Удаление модуля:
```console
semodule -r nginx
```
```
libsemanage.semanage_direct_remove_key: Removing last nginx module (no other nginx module exists at another priority).
```