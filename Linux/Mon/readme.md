# Мониторинг.

## Описание задачи

Настроить дашборд с 4-мя графиками:
- память;
- процессор;
- диск;
- сеть.

В качестве результата прислать скриншот экрана - дашборд должен содержать в названии имя приславшего.

## Выполнение

Развернута ВМ при помощи Vagrantfile.

### 1. Установка и настройка Zabbix.

Произведены следующие действия:
```console
sudo -i
setenforce 0
systemctl stop firewalld
systemctl disable firewalld
rpm --import https://repo.almalinux.org/almalinux/RPM-GPG-KEY-AlmaLinux
yum install -y net-tools bind-utils chrony net-snmp net-snmp-utils epel-release
yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
yum -qy module disable postgresql
yum install -y postgresql14-server
/usr/pgsql-14/bin/postgresql-14-setup initdb
systemctl enable postgresql-14
systemctl start postgresql-14
rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/8/x86_64/zabbix-release-6.0-5.el8.noarch.rpm
yum clean all
yum makecache
yum install -y zabbix-server-pgsql zabbix-web-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent
sudo -u postgres createuser --pwprompt zabbix
sudo -u postgres createdb -O zabbix zabbix
zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix
yum update -y
```
Далее в `/etc/zabbix_server.conf` прописан `DBPassword=`,
в `/etc/nginx/conf.d/zabbix.conf` раскомментированы строки `listen 8080;` и `server_name example.com;`,
в `/var/lib/pgsql/14/data/pg_hba.conf` в сегментах local и host выставлен метод `md5`:
```
# "local" is for Unix domain socket connections only
local   all             all                                     md5
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
```
Затем
```
systemctl restart postgresql-14
systemctl restart zabbix-server zabbix-agent nginx php-fpm
systemctl enable zabbix-server zabbix-agent nginx php-fpm
```

### 2. Настройка zabbix agent

На хосте Windows установлен и запущен zabbix agent.
В `zabbix-agentd.conf` прописано:
```
ServerActive=127.0.0.1
```

### 3. Добавление хоста в мониторинг

Через веб-интерфейс Zabbix в Configurations -> Actions -> Autoregistration actions прописаны операции:
![Image alt]()

### 4. Результат

Настроен дашборд с метриками, которые собраны с Windows хоста.

![Image alt]()