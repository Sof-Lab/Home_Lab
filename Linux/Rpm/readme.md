# Vagrant стeнд для работы с rpm

## Описание задачи

1. Создать свой RPM;
2. создать свой репо и разместить там свой RPM.

## Выполнение

### 1. Запуск ВМ с помощью vagrant.

Создан Vagrantfile для разворачивания лабороторного стенда.
Установка необходимых утилит:
```
yum install -y wget rpmdevtools rpm-build createrepo yum-utils cmake gcc git nano lynx
yum update -y
```

### 2. Создание RPM.

Скачивание исходников nginx:
```
[root@rpm ~]# mkdir rpm && cd rpm
[root@rpm rpm]#  yumdownloader --source nginx 
```
Установка зависимостей для сборки:
```
[root@rpm rpm]# rpm -Uvh nginx*.src.rpm
[root@rpm rpm]#  yum-builddep nginx
```
Скачивание исходного кода модуля, который будет добавлен в сборку:
```
[root@rpm rpm]#  cd /root
[root@rpm ~]#  git clone --recurse-submodules -j8 \
[root@rpm ~]#  cd ngx_brotli/deps/brotli
[root@rpm brotli]# mkdir out && cd out
```
Сборка дополнительного модуля:
```
[root@rpm out]# cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_CXX_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_INSTALL_PREFIX=./installed ..
[root@rpm out]# cmake --build . --config Release -j 2 --target brotlienc
[root@rpm out]# cd ../../../..
```
Далее нужно добавить `--add-module=/root/ngx_brotli \` в `SPECS/nginx.spec` в блок `configure`:
```
nano ~/rpmbuild/SPECS/nginx.spec
```
```
...
if ! ./configure \
    --prefix=%{_datadir}/nginx \
    --sbin-path=%{_sbindir}/nginx \
    --modules-path=%{nginx_moduledir} \
    --conf-path=%{_sysconfdir}/nginx/nginx.conf \
    --error-log-path=%{_localstatedir}/log/nginx/error.log \
    --http-log-path=%{_localstatedir}/log/nginx/access.log \
    --http-client-body-temp-path=%{_localstatedir}/lib/nginx/tmp/client_body \
    --http-proxy-temp-path=%{_localstatedir}/lib/nginx/tmp/proxy \
    --http-fastcgi-temp-path=%{_localstatedir}/lib/nginx/tmp/fastcgi \
    --http-uwsgi-temp-path=%{_localstatedir}/lib/nginx/tmp/uwsgi \
    --http-scgi-temp-path=%{_localstatedir}/lib/nginx/tmp/scgi \
    --pid-path=/run/nginx.pid \
    --lock-path=/run/lock/subsys/nginx \
    --user=%{nginx_user} \
    --group=%{nginx_user} \
    --with-compat \
    --with-debug \
    --add-module=/root/ngx_brotli \
%if 0%{?with_aio}
...
```
Сборка пакета:
```
[root@rpm SPECS]# rpmbuild -ba nginx.spec -D 'debug_package %{nil}'
```
```
...
+ cd /root/rpmbuild/BUILD
+ cd nginx-1.20.1
+ /usr/bin/rm -rf /root/rpmbuild/BUILDROOT/nginx-1.20.1-20.el9.alma.1.x86_64
+ RPM_EC=0
++ jobs -p
+ exit 0
```
Копирование пакетов в общий каталог:
```
[root@rpm rpmbuild]# cp ~/rpmbuild/RPMS/noarch/* ~/rpmbuild/RPMS/x86_64/
[root@rpm rpmbuild]# cd ~/rpmbuild/RPMS/x86_64
```
Установка собранного пакета:
```
[root@rpm x86_64]#  yum localinstall *.rpm
```
Запуск приложения:
```
[root@rpm x86_64]# systemctl start nginx
[root@rpm x86_64]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: disabled)
     Active: active (running) since Sun 2024-11-24 19:33:33 UTC; 4s ago
    Process: 97983 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 97984 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 97985 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 97986 (nginx)
      Tasks: 3 (limit: 11051)
     Memory: 5.5M
        CPU: 55ms
     CGroup: /system.slice/nginx.service
             ├─97986 "nginx: master process /usr/sbin/nginx"
             ├─97987 "nginx: worker process"
             └─97988 "nginx: worker process"

Nov 24 19:33:33 rpm systemd[1]: Starting The nginx HTTP and reverse proxy server...
Nov 24 19:33:33 rpm nginx[97984]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Nov 24 19:33:33 rpm nginx[97984]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Nov 24 19:33:33 rpm systemd[1]: Started The nginx HTTP and reverse proxy server.
```
Задача выполнена, nginx собран из исходных кодов с добавлением модуля, запущен и работает.

### 3. Создание репозитория.

Создание каталога с репо и копирование в него собранных rpm пакетов:
```
[root@rpm x86_64]# mkdir /usr/share/nginx/html/repo
[root@rpm x86_64]# cp ~/rpmbuild/RPMS/x86_64/*.rpm /usr/share/nginx/html/repo/
```
Инициализация репозитория:
```
[root@rpm x86_64]# createrepo /usr/share/nginx/html/repo/
Directory walk started
Directory walk done - 10 packages
Temporary output repo path: /usr/share/nginx/html/repo/.repodata/
Preparing sqlite DBs
Pool started (with 5 workers)
Pool finished
```
Настройка конфига nginx для доступа к репо (добавление в блок `server`
index index.html index.htm;
autoindex on;
```
[root@rpm x86_64]# nano /etc/nginx/nginx.conf
```
```
...
    server {
        listen       80;
        listen       [::]:80;
        server_name  _;
        root         /usr/share/nginx/html;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        index index.html index.htm;
        autoindex on;

        error_page 404 /404.html;
        location = /404.html {
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
        }
    }
...
```
Проверка наличия ошибок в nginx.conf:
```
[root@rpm x86_64]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```
Ошибок нет, применение нового конфига:
```
[root@rpm x86_64]# nginx -s reload
```
Проверка наличия rmp пакетов в репо:
```
[root@rpm x86_64]# lynx http://localhost/repo/


                                                             Index of /repo/
     ____________________________________________________________________________________________________________________________

../
repodata/                                          24-Nov-2024 19:50                   -
nginx-1.20.1-20.el9.alma.1.x86_64.rpm              24-Nov-2024 19:44               36225
nginx-all-modules-1.20.1-20.el9.alma.1.noarch.rpm  24-Nov-2024 19:44                7341
nginx-core-1.20.1-20.el9.alma.1.x86_64.rpm         24-Nov-2024 19:44             1018619
nginx-filesystem-1.20.1-20.el9.alma.1.noarch.rpm   24-Nov-2024 19:44                8424
nginx-mod-devel-1.20.1-20.el9.alma.1.x86_64.rpm    24-Nov-2024 19:44              759644
nginx-mod-http-image-filter-1.20.1-20.el9.alma...> 24-Nov-2024 19:44               19354
nginx-mod-http-perl-1.20.1-20.el9.alma.1.x86_64..> 24-Nov-2024 19:44               30997
nginx-mod-http-xslt-filter-1.20.1-20.el9.alma.1..> 24-Nov-2024 19:44               18150
nginx-mod-mail-1.20.1-20.el9.alma.1.x86_64.rpm     24-Nov-2024 19:44               53795
nginx-mod-stream-1.20.1-20.el9.alma.1.x86_64.rpm   24-Nov-2024 19:44               80428
percona-release-latest.noarch.rpm                  04-Jul-2024 09:46               27900
     ____________________________________________________________________________________________________________________________
```
```
[root@rpm x86_64]# curl -a http://localhost/repo/
<html>
<head><title>Index of /repo/</title></head>
<body>
<h1>Index of /repo/</h1><hr><pre><a href="../">../</a>
<a href="repodata/">repodata/</a>                                          24-Nov-2024 19:44                   -
<a href="nginx-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-1.20.1-20.el9.alma.1.x86_64.rpm</a>              24-Nov-2024 19:44               36225
<a href="nginx-all-modules-1.20.1-20.el9.alma.1.noarch.rpm">nginx-all-modules-1.20.1-20.el9.alma.1.noarch.rpm</a>  24-Nov-2024 19:44                7341
<a href="nginx-core-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-core-1.20.1-20.el9.alma.1.x86_64.rpm</a>         24-Nov-2024 19:44
1018619
<a href="nginx-filesystem-1.20.1-20.el9.alma.1.noarch.rpm">nginx-filesystem-1.20.1-20.el9.alma.1.noarch.rpm</a>   24-Nov-2024 19:44                8424
<a href="nginx-mod-devel-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-mod-devel-1.20.1-20.el9.alma.1.x86_64.rpm</a>    24-Nov-2024 19:44              759644
<a href="nginx-mod-http-image-filter-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-mod-http-image-filter-1.20.1-20.el9.alma...&gt;</a> 24-Nov-2024 19:44               19354
<a href="nginx-mod-http-perl-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-mod-http-perl-1.20.1-20.el9.alma.1.x86_64..&gt;</a> 24-Nov-2024 19:44               30997
<a href="nginx-mod-http-xslt-filter-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-mod-http-xslt-filter-1.20.1-20.el9.alma.1..&gt;</a> 24-Nov-2024 19:44               18150
<a href="nginx-mod-mail-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-mod-mail-1.20.1-20.el9.alma.1.x86_64.rpm</a>     24-Nov-2024 19:44
      53795
<a href="nginx-mod-stream-1.20.1-20.el9.alma.1.x86_64.rpm">nginx-mod-stream-1.20.1-20.el9.alma.1.x86_64.rpm</a>   24-Nov-2024 19:44               80428
</pre><hr></body>
</html>
```
Добавление созданного репозитория в репо-лист:
```
[root@rpm x86_64]# cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF
```
Проверка содержания репозитория:
```
[root@rpm x86_64]# yum repolist enabled | grep otus
otus                otus-linux

[root@rpm x86_64]# yum list | grep otus
otus-linux                                      434 kB/s | 6.7 kB     00:00
```
Добавление пакета в репозиторий:
```
[root@rpm x86_64]# cd /usr/share/nginx/html/repo/

[root@rpm repo]# wget https://repo.percona.com/yum/percona-release-latest.noarch.rpm
```
Обновление списка пакетов в репозитории:
```
[root@rpm repo]# createrepo /usr/share/nginx/html/repo/

Directory walk started
Directory walk done - 11 packages
Temporary output repo path: /usr/share/nginx/html/repo/.repodata/
Preparing sqlite DBs
Pool started (with 5 workers)
Pool finished

[root@rpm repo]# yum makecache
```
Проверка результатов:
```
[root@rpm repo]# yum list | grep otus
percona-release.noarch                                                                   1.0-29                               otus
```
Установка нового репозитория:
```
[root@rpm repo]# yum install -y percona-release.noarch
```