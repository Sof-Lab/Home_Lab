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
В нём нужно указать ip-адрес хоста и желаемый порт ssh для подключения:

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

После запуска playbook непозиторий уже будет инициализирован, бэкапы будут создаваться и удаляться по расписанию.

### 3. Проверка результатов.

Можно посмотреть логи borg:

![Image alt]()

### 4. Восстановление из бэкапа.

Остановка 

### 5. Полезные команды.

```comand
borg list borg@192.168.11.160:client1
borg delete borg@192.168.11.160:client1
borg break-lock borg@192.168.11.160:client1
```