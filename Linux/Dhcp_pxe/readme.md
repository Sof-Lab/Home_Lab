# Vagrant-стенд c PXE

## Описание задачи

1. Настроить загрузку по сети дистрибутива Ubuntu 24
2. Установка должна проходить из HTTP-репозитория.
3. Настроить автоматическую установку c помощью файла user-data

## Выполнение

*Лабораторный стенд развёрнут на хосте с Windows + WSL2. На Windows установлены Vagrant и VirtualBox. Ansible установлен на WSL.*

*Все файлы для vagrant располагаются в директории windows (win_directory), у меня это - D:\VBox_Projects\dhcp_pxe\. Команды для работы с vagrant запускаются из той же директории.*

*Все файлы для ansible располагаются в директории wsl (wsl_directory), у меня это - /home/sof/sof/otus_labs/dhcp_pxe/. Команды для работы с ansible звпускаются из той же директории.*

### 1. Запуск pxe server с помощью vagrant.

Для доступа к ВМ из wsl в Vagrantfile прописан дополнительный проброс порта `ssh-for-wsl`.
В нём нужно указать ip-адрес хоста и желаемый порт ssh для подключения:
```
host: 2230, # Порт для подключения по ssh
host_ip: "192.168.1.8", # Ip-адрес Windows-хоста
```
Сначала нужно запустить pxeserver командой `vagrant up pxeserver`.

### 2. Настройка pxe server с помощью ansible.

В файле staging/hosts.yaml нужно заполнить переменные для выполнения настройки ВМ:
```
all:
  vars:
    host_ip: 192.168.1.8				# Ip-адрес Windows-хоста
    dir_wsl: /home/sof/otus_labs/dhcp_pxe/	# Директория wsl, где расположены файлы windows-хоста для работы с vagrant
    dir_vagrant: /mnt/d/VBox_Projects/dhcp_pxe/	 # Директория wsl, где расположены файлы ansible
    vm_name: pxeserver					# имя ВМ в VB
    vm_port: 2230						# Порт для подключения по ssh
```

В файле staging/hosts.yaml прописан localhost для выполнения команд в wsl.
Это требуется, чтобы скопировать ключ private_key для подключения к ВМ из директории windows в директорию wsl.

После запуска и выполнения pxe.yml сервер будет настроен.

### 3. Запуск pxe client.

При помощи `vagrant up pxeclient` запускается вм и далее автоматически устанавливается ВМ с прописанными в user-data настройками.
По завершении нужно выключить вм, в Virtualbox изменить загрузку с сети на загрузку с диска и запустить вм.
Результат:

![Image alt](https://github.com/Sof-Lab/Home_Lab/blob/main/Linux/Dhcp_pxe/results/pxeclient.png)

### 4. Полезные команды.

Просмотр выданных ip-адресов на dhcp сервере:
`cat /var/lib/misc/dnsmasq.leases`.

Генерация хэша для пароля (предустановить пакет whois):
`mkpasswd -m sha-512 123 -S [SALT]`.