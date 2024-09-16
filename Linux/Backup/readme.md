# Vagrant-Ansible стeнд для borg

## Описание задачи

Настроить стенд Vagrant с двумя виртуальными машинами: backup_server и client.
Настроить удаленный бекап каталога /etc c сервера client при помощи borgbackup.

## Выполнение

*Лабораторный стенд развёрнут на хосте с Windows + WSL2. На Windows установлены Vagrant и VirtualBox. Ansible установлен на WSL.*

*Все файлы для vagrant располагаются в директории windows (win_directory), у меня это - D:\VBox_Projects\backup\. Команды для работы с vagrant запускаются из той же директории.*

*Все файлы для ansible располагаются в директории wsl (wsl_directory), у меня это - /home/sof/sof/otus_labs/backup/. Команды для работы с ansible звпускаются из той же директории.*

### 1. Запуск ВМ с помощью vagrant.

Для доступа к ВМ из wsl в Vagrantfile прописан дополнительный проброс порта `ssh-for-wsl`.
В нём нужно указать ip-адрес хоста и желаемый порт ssh для подключения.

Часть `file_to_disk` создает дополнительный диск объемом 2Гб.

### 2. Настройка ВМ с помощью ansible.

В файле staging/hosts.yaml нужно заполнить переменные для выполнения настройки ВМ:
```
all:
  vars: 
    host_ip: 192.168.1.8   						  # Ip-адрес Windows-хоста
    dir_wsl: /home/sof/otus_labs/backup/    	  # Директория wsl, где расположены файлы ansible
	dir_vagrant: /mnt/d/VBox_Projects/backup/     # Директория wsl, где расположены файлы windows-хоста для работы с vagrant

    vm_name:        	  # имя ВМ в VB
    vm_port:          	  # Порт для подключения по ssh

    dir_borg: /mnt/bcp	  # Директория для бэкапов
    user_borg: borg		  # Пользователь Borg
	
    repo: client1		  # Рпозиторий для клиента
    passphrase: borg	  # Парольная фраза для доступа к репо
```

В файле staging/hosts.yaml прописан localhost для выполнения команд в wsl.
Это требуется, чтобы скопировать ключ private_key для подключения к ВМ из директории windows в директорию wsl.

В play "Configure bcp_srv" происходит монтирование диска, создание пользователя borg, создание директории файла для дальнейшего соединения по ssh с ключом.
В play "Configure bcp_clnt" происходит генерация ключа для соединения по ssh, а также инициализация репозитория borg через скрипт borg-init.sh.

### 3. Проверка результатов.

Можно посмотреть логи borg:

![Image alt](https://github.com/Sof-Lab/Home_Lab/blob/main/Linux/Backup/results/Log.png)

### 4. Восстановление из бэкапа.

Для теста создам файл check_file.txt в директории etc:
```comand
root@bcp-clnt:/# cat /etc/check_file.txt
If you're reading this, it means it works.
```

Убедимся, что в последнем бэкапе есть этот файл:
```comand
root@bcp-clnt:/# borg list borg@192.168.11.160:client1 | awk 'END {print $1}'
Enter passphrase for key ssh://borg@192.168.11.160/./client1:
etc-2024-09-17_00:59:46
root@bcp-clnt:/# borg list borg@192.168.11.160:client1::etc-2024-09-17_00:59:46 | grep check_file
Enter passphrase for key ssh://borg@192.168.11.160/./client1:
-rw-r--r-- root   root         43 Mon, 2024-09-16 22:20:38 etc/check_file.txt
```

Остановка бэкапа:
```comand
root@bcp-clnt:/# systemctl stop borg-backup.timer
root@bcp-clnt:/# systemctl status borg-backup.timer
○ borg-backup.timer - Borg Backup
     Loaded: loaded (/etc/systemd/system/borg-backup.timer; enabled; vendor preset: enabled)
     Active: inactive (dead) since Tue 2024-09-17 01:03:05 MSK; 7s ago
    Trigger: n/a
   Triggers: ● borg-backup.service

Sep 17 00:48:41 bcp-clnt systemd[1]: Started Borg Backup.
Sep 17 01:03:05 bcp-clnt systemd[1]: borg-backup.timer: Deactivated successfully.
Sep 17 01:03:05 bcp-clnt systemd[1]: Stopped Borg Backup.
```

Перенос директории etc:
```comand
root@bcp-clnt:/# mv /etc /tmp/etc
root@bcp-clnt:/# ls /
bin   dev   lib    lib64   lost+found  mnt  proc  run   snap  swap.img  tmp  var
boot  home  lib32  libx32  media       opt  root  sbin  srv   sys       usr
```

Теперь подключиться к серверу с бэкапами не удается:
```comand
root@bcp-clnt:/# borg list borg@192.168.11.160:client1
Remote: No user exists for uid 0
Connection closed by remote host. Is borg working on the server?
```

Управление сервером потеряно: не работает user login management, режим восстановления системы недоступен.
Для восстановления удалим вм, создадим её заново, затем восстановим директорию etc из бэкапа.

```comand
PS D:\VBox_Projects\backup> vagrant destroy bcp_clnt
    bcp_clnt: Are you sure you want to destroy the 'bcp_clnt' VM? [y/N] y
==> bcp_clnt: Forcing shutdown of VM...
==> bcp_clnt: Destroying VM and associated drives...
PS D:\VBox_Projects\backup> vagrant up bcp_clnt
```

Зайдем на новую вм и убедимся, что в etc отсутствует файл check_file.txt:
 
```comand
root@bcp-clnt:~# ls /etc/check_file.txt
ls: cannot access '/etc/check_file.txt': No such file or directory
```

Для восстановления воспользуюсь ansible playbook "bcp_recover_clnt.yml".
В play "Configure bcp_clnt" происходит генерация нового ключа для соединения с сервером по ssh и восстановление etc при помощи скриптов borg-recover.sh и borg-recover-expect.sh.
После запуска проверим, что в etc присутствует файл check_file.txt:

```comand
root@bcp-clnt:~# ls /etc/check_file.txt
/etc/check_file.txt
root@bcp-clnt:~# cat /etc/check_file.txt
If you're reading this, it means it works.
```

Проверим, что после восстановления свежие бэкапы продолжают сохраняться через логи:

![Image alt](https://github.com/Sof-Lab/Home_Lab/blob/main/Linux/Backup/results/Log_new.png)

Успешно.

### 5. Полезные команды.

```comand
borg list
borg delete
borg break-lock
borg export-tar
```