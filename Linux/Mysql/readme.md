# Vagrant-Ansible стeнд для работы с Mysql: Репликация Percona

## Описание задачи

1. Установить percona и настроить репликацию mysql.
2. Развернуть базу bet из материалов к заданию на мастере, настроить репликацию таблиц:
| bookmaker          |
| competition        |
| market             |
| odds               |
| outcome			 |

## Выполнение

*Лабораторный стенд развёрнут на хосте с Windows + WSL2. На Windows установлены Vagrant и VirtualBox. Ansible установлен на WSL.*

*Все файлы для vagrant располагаются в директории windows (win_directory), у меня это - D:\VBox_Projects\mysql\. Команды для работы с vagrant запускаются из той же директории.*

*Все файлы для ansible располагаются в директории wsl (wsl_directory), у меня это - /home/sof/sof/otus_labs/mysql/. Команды для работы с ansible звпускаются из той же директории.*

### 1. Разворачивание стенда при помощи Vagrant.

Создан Vagrantfile *(win_directory)* для разворачивания лабороторного стенда.

Для доступа к вм из wsl в Vagrantfile прописан дополнительный проброс порта `ssh-for-wsl` для каждой вм.
В нём нужно указать ip-адрес хоста и желаемый порт ssh для подключения для каждой вм:

```
:wsl =>	'указать номер порта для подключения по ssh к каждой вм'
box.vm.network "forwarded_port", auto_correct: true, guest: 22, host: boxconfig[:wsl], host_ip: "Ip-адрес Windows-хоста", id: "ssh-for-wsl"
```

### 2. Настройка стенда при помощи Ansible.

В файле staging/hosts.yaml *(wsl_directory)* нужно заполнить переменные для выполнения настройки стенда.
Для подключения к ВМ:
```
    host_ip: 192.168.1.8 # windows host ip
    dir_wsl: /home/sof/otus_labs/mysql/ # directory wsl whith ansible files
    dir_vagrant: /mnt/d/VBox_Projects/mysql/ # directory wsl whith vagrant files
	
	ansible_port: 'указать порт для подключения по ssh' # указывается к каждой вм согласно настройкам в Vagrantfile ":wsl"
```
Также в staging/hosts.yaml *(wsl_directory)* добавлены переменные для дальнейшего использования в конфиг файлах:
```
    mysql_pass: 'пароль для пользователя root в mysql'
    repl_user: 'имя пользователя для реплики'
    repl_pass: 'пароль для реплики'
	
    comment: 'указать # для мастер базы'
    server_id: 'указать разные id для каждой вм'
```
В файле staging/hosts.yaml *(wsl_directory)* дополнительно прописан localhost для выполнения команд в wsl.
Это требуется, чтобы скопировать ключ private_key для подключения к ВМ из директории windows в директорию wsl.

PLAY `WSL localhost copy private_key` в `mysql.yml` *(wsl_directory)* копирует private_key на wsl.
PLAY `Configure Replication Mysql` в `mysql.yml` *(wsl_directory)* производит необходимые настройки.

### 3. Проверка результатов.

Проверка server_id на мастере:
```
mysql> SELECT @@server_id;
+-------------+
| @@server_id |
+-------------+
|           1 |
+-------------+
1 row in set (0.00 sec)
```
Проверка server_id на реплике:
```
mysql> SELECT @@server_id;
+-------------+
| @@server_id |
+-------------+
|           2 |
+-------------+
1 row in set (0.00 sec)
```
Проверка gtid_mode на мастере:
```
mysql> SHOW VARIABLES LIKE 'gtid_mode';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| gtid_mode     | ON    |
+---------------+-------+
1 row in set (0.00 sec)
```
Проверка gtid_mode на реплике:
```
mysql> SHOW VARIABLES LIKE 'gtid_mode';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| gtid_mode     | ON    |
+---------------+-------+
1 row in set (0.00 sec)
```
Просмотр списка таблиц базы bet на мастере:
```
mysql> USE bet;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> SHOW TABLES;
+------------------+
| Tables_in_bet    |
+------------------+
| bookmaker        |
| competition      |
| events_on_demand |
| market           |
| odds             |
| outcome          |
| v_same_event     |
+------------------+
7 rows in set (0.00 sec)
```
Просмотр списка таблиц базы bet на реплике:
```
mysql> USE bet;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> SHOW TABLES;
+---------------+
| Tables_in_bet |
+---------------+
| bookmaker     |
| competition   |
| market        |
| odds          |
| outcome       |
+---------------+
5 rows in set (0.00 sec)
```
Проверка статуса мастера:
```
mysql> SHOW MASTER STATUS;
+------------------+----------+--------------+------------------+-------------------------------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set                         |
+------------------+----------+--------------+------------------+-------------------------------------------+
| mysql-bin.000005 |      464 |              |                  | e3575e47-c48a-11ef-882f-080027ddec34:1-40 |
+------------------+----------+--------------+------------------+-------------------------------------------+
1 row in set (0.00 sec)
```
Проверка статуса мастера на реплике:
```
mysql> SHOW MASTER STATUS;
+------------------+----------+--------------+------------------+-------------------------------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set                         |
+------------------+----------+--------------+------------------+-------------------------------------------+
| mysql-bin.000005 |      464 |              |                  | e3575e47-c48a-11ef-882f-080027ddec34:1-40 |
+------------------+----------+--------------+------------------+-------------------------------------------+
1 row in set (0.00 sec)
```
Проверка статуса реплики:
```
mysql> SHOW SLAVE STATUS;
+----------------------------------+----------------+-------------+-------------+---------------+------------------+---------------------+-------------------------+---------------+-----------------------+------------------+-------------------+-----------------+---------------------+--------------------+---------------------------------------+-------------------------+-----------------------------+------------+------------+--------------+---------------------+-----------------+-----------------+----------------+---------------+--------------------+--------------------+--------------------+-----------------+-------------------+----------------+-----------------------+-------------------------------+---------------+---------------+----------------+----------------+-----------------------------+------------------+--------------------------------------+----------------------------+-----------+---------------------+--------------------------------------------------------+--------------------+-------------+-------------------------+--------------------------+----------------+--------------------+-------------------------------------------+-------------------------------------------------------------------------------------------+---------------+----------------------+--------------+--------------------+
| Slave_IO_State                   | Master_Host    | Master_User | Master_Port | Connect_Retry | Master_Log_File  | Read_Master_Log_Pos | Relay_Log_File          | Relay_Log_Pos | Relay_Master_Log_File | Slave_IO_Running | Slave_SQL_Running | Replicate_Do_DB | Replicate_Ignore_DB | Replicate_Do_Table | Replicate_Ignore_Table                | Replicate_Wild_Do_Table | Replicate_Wild_Ignore_Table | Last_Errno | Last_Error | Skip_Counter | Exec_Master_Log_Pos | Relay_Log_Space | Until_Condition | Until_Log_File | Until_Log_Pos | Master_SSL_Allowed | Master_SSL_CA_File | Master_SSL_CA_Path | Master_SSL_Cert | Master_SSL_Cipher | Master_SSL_Key | Seconds_Behind_Master | Master_SSL_Verify_Server_Cert | Last_IO_Errno | Last_IO_Error | Last_SQL_Errno | Last_SQL_Error | Replicate_Ignore_Server_Ids | Master_Server_Id | Master_UUID                          | Master_Info_File           | SQL_Delay | SQL_Remaining_Delay | Slave_SQL_Running_State
    | Master_Retry_Count | Master_Bind | Last_IO_Error_Timestamp | Last_SQL_Error_Timestamp | Master_SSL_Crl | Master_SSL_Crlpath | Retrieved_Gtid_Set                        | Executed_Gtid_Set
                                         | Auto_Position | Replicate_Rewrite_DB | Channel_Name | Master_TLS_Version |
+----------------------------------+----------------+-------------+-------------+---------------+------------------+---------------------+-------------------------+---------------+-----------------------+------------------+-------------------+-----------------+---------------------+--------------------+---------------------------------------+-------------------------+-----------------------------+------------+------------+--------------+---------------------+-----------------+-----------------+----------------+---------------+--------------------+--------------------+--------------------+-----------------+-------------------+----------------+-----------------------+-------------------------------+---------------+---------------+----------------+----------------+-----------------------------+------------------+--------------------------------------+----------------------------+-----------+---------------------+--------------------------------------------------------+--------------------+-------------+-------------------------+--------------------------+----------------+--------------------+-------------------------------------------+-------------------------------------------------------------------------------------------+---------------+----------------------+--------------+--------------------+
| Waiting for master to send event | 192.168.11.150 | repl        |        3306 |            60 | mysql-bin.000005 |                 464 | relay-log-server.000008 |           677 | mysql-bin.000005      | Yes              | Yes               |                 |                     |
   | bet.events_on_demand,bet.v_same_event |                         |                             |          0 |            |            0 |
        464 |             925 | None            |                |
    0 | No                 |                    |                    |                 |                   |                |                     0 | No                            |             0 |               |
  0 |                |                             |                1 | e3575e47-c48a-11ef-882f-080027ddec34 | /var/lib/mysql/master.info |         0 |                NULL | Slave has read all relay log; waiting for more updates |              86400 |             |                         |
                 |                |                    | e3575e47-c48a-11ef-882f-080027ddec34:1-40 | e3575e47-c48a-11ef-882f-080027ddec34:1:3-37:39-40,
e37131c6-c48a-11ef-8902-080027ddec34:1 |             1 |
   |              |                    |
+----------------------------------+----------------+-------------+-------------+---------------+------------------+---------------------+-------------------------+---------------+-----------------------+------------------+-------------------+-----------------+---------------------+--------------------+---------------------------------------+-------------------------+-----------------------------+------------+------------+--------------+---------------------+-----------------+-----------------+----------------+---------------+--------------------+--------------------+--------------------+-----------------+-------------------+----------------+-----------------------+-------------------------------+---------------+---------------+----------------+----------------+-----------------------------+------------------+--------------------------------------+----------------------------+-----------+---------------------+--------------------------------------------------------+--------------------+-------------+-------------------------+--------------------------+----------------+--------------------+-------------------------------------------+-------------------------------------------------------------------------------------------+---------------+----------------------+--------------+--------------------+
1 row in set (0.00 sec)
```
```
mysql> SHOW SLAVE STATUS\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 192.168.11.150
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000005
          Read_Master_Log_Pos: 464
               Relay_Log_File: relay-log-server.000008
                Relay_Log_Pos: 677
        Relay_Master_Log_File: mysql-bin.000005
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB:
          Replicate_Ignore_DB:
           Replicate_Do_Table:
       Replicate_Ignore_Table: bet.events_on_demand,bet.v_same_event
      Replicate_Wild_Do_Table:
  Replicate_Wild_Ignore_Table:
                   Last_Errno: 0
                   Last_Error:
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 464
              Relay_Log_Space: 925
              Until_Condition: None
               Until_Log_File:
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File:
           Master_SSL_CA_Path:
              Master_SSL_Cert:
            Master_SSL_Cipher:
               Master_SSL_Key:
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error:
               Last_SQL_Errno: 0
               Last_SQL_Error:
  Replicate_Ignore_Server_Ids:
             Master_Server_Id: 1
                  Master_UUID: e3575e47-c48a-11ef-882f-080027ddec34
             Master_Info_File: /var/lib/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind:
      Last_IO_Error_Timestamp:
     Last_SQL_Error_Timestamp:
               Master_SSL_Crl:
           Master_SSL_Crlpath:
           Retrieved_Gtid_Set: e3575e47-c48a-11ef-882f-080027ddec34:1-40
            Executed_Gtid_Set: e3575e47-c48a-11ef-882f-080027ddec34:1:3-37:39-40,
e37131c6-c48a-11ef-8902-080027ddec34:1
                Auto_Position: 1
         Replicate_Rewrite_DB:
                 Channel_Name:
           Master_TLS_Version:
1 row in set (0.00 sec)
```
Добавим на мастере запись в одну из таблиц:
```
mysql> INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'1xbet');
Query OK, 1 row affected (0.02 sec)

mysql> SELECT * FROM bookmaker;
+----+----------------+
| id | bookmaker_name |
+----+----------------+
|  1 | 1xbet          |
|  4 | betway         |
|  5 | bwin           |
|  6 | ladbrokes      |
|  3 | unibet         |
+----+----------------+
5 rows in set (0.00 sec)
```
Проверка наличия новой записи на реплике:
```
mysql> SELECT * FROM bookmaker;
+----+----------------+
| id | bookmaker_name |
+----+----------------+
|  1 | 1xbet          |
|  4 | betway         |
|  5 | bwin           |
|  6 | ladbrokes      |
|  3 | unibet         |
+----+----------------+
5 rows in set (0.00 sec)

mysql>
```
Задача выполнена.