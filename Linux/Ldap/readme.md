# Vagrant-Ansible стeнд c LDAP на базе FreeIPA

## Описание задачи

1. Установить FreeIPA
2. Написать Ansible-playbook для конфигурации клиента

## Выполнение

*Лабораторный стенд развёрнут на хосте с Windows + WSL2. На Windows установлены Vagrant и VirtualBox. Ansible установлен на WSL.*

*Все файлы для vagrant располагаются в директории windows (win_directory), у меня это - D:\VBox_Projects\ldap\. Команды для работы с vagrant запускаются из той же директории.*

*Все файлы для ansible располагаются в директории wsl (wsl_directory), у меня это - /home/sof/sof/otus_labs/ldap/. Команды для работы с ansible звпускаются из той же директории.*

### 1. Разворачивание стенда при помощи Vagrant.

Создан Vagrantfile *(win_directory)* для разворачивания лабороторного стенда.

Для доступа к вм из wsl в Vagrantfile прописан дополнительный проброс порта `ssh-for-wsl` для каждой вм.
В нём нужно указать ip-адрес хоста и желаемый порт ssh для подключения для каждой вм:

```
:wsl => 'указать порт для подключения по ssh', # Порт для подключения по ssh
config.vm.network "forwarded_port", auto_correct: true, guest: 22, host: opts[:wsl], host_ip: "указать ip-адрес хоста", id: "ssh-for-wsl"
```

### 2. Настройка сервера LDAP на базе FreeIPA.

На сервере `ipa.otus.lan` выполнены настройки:
```
sudo -i
yum install -y chrony
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
yum -y install java
yum install -y chrony
systemctl enable chronyd
systemctl start chronyd
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
yum install -y @idm:DL1
yum install -y ipa-server
```
В файл `/etc/hosts` добавлена запись `192.168.57.10 ipa.otus.lan ipa`.
В файле `/etc/selinux/config` установлено значение `SELINUX=disabled`.
Далее командой `ipa-server-install` запускается скрипт установки ldap.
В диалоговом окне вводятся значения:
```
Do you want to configure integrated DNS (BIND)? [no]: no
Server host name [ipa.otus.lan]: <Нажимаем Enter>
Please confirm the domain name [otus.lan]: <Нажимем Enter>
Please provide a realm name [OTUS.LAN]: <Нажимаем Enter>
Directory Manager password: <Указываем пароль минимум 8 символов>
Password (confirm): <Дублируем указанный пароль>
IPA admin password: <Указываем пароль минимум 8 символов>
Password (confirm): <Дублируем указанный пароль>
NetBIOS domain name [OTUS]: <Нажимаем Enter>
Continue to configure the system with these values? [no]: yes
```
Для входа в веб-интерфейс сервера на хосте в файл `C:\Windows\System32\Drivers\etc\hosts` добавлена запись `192.168.57.10 ipa.otus.lan`.

### 3. Настройка клиентов при помощи Ansible.

В файле staging/hosts.yaml *(wsl_directory)* нужно заполнить переменные для выполнения настройки стенда.
Для подключения к ВМ:
```
    host_ip: 192.168.1.8 # windows host ip
    dir_wsl: /home/sof/otus_labs/ldap/ # directory wsl whith ansible files
    dir_vagrant: /mnt/d/VBox_Projects/ldap/ # directory wsl whith vagrant files
	
	ansible_port: 'указать порт для подключения по ssh' # указывается к каждой вм согласно настройкам в Vagrantfile ":wsl"
```
В файле staging/hosts.yaml *(wsl_directory)* дополнительно прописан localhost для выполнения команд в wsl.
Это требуется, чтобы скопировать ключ private_key для подключения к ВМ из директории windows в директорию wsl.

В `ldap.yml` TASK `Add host to ipa-server` нужно ввести пароль от пользователя FreeIPA admin в части `-w 'your_pass'`.

PLAY `WSL localhost copy private_key` копирует private_key на wsl.
PLAY `Configure ldap clients` настраивает клиентов.

### 4. Проверка результатов.

На сервере создан пользователь otus-user:
```
kinit admin
ipa user-add otus-user --first=Otus --last=User --password
```
На клиенте client1 выполнено:
```
kinit otus-user
```
На хосте client2 выполним подключение к client1 с новым юзером:
```
[vagrant@client2 ~]$ ssh otus-user@192.168.57.11
The authenticity of host '192.168.57.11 (<no hostip for proxy command>)' can't be established.
ECDSA key fingerprint is SHA256:MrYRfryclUzT0O5+UYvrlmfutwG8k2Ojjt2teJ3qNVk.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.57.11' (ECDSA) to the list of known hosts.
Password:
[otus-user@client1 ~]$
```
Успешно.

В веб-интерфейсе можно посмотреть список активных пользователей:

![Image alt](https://github.com/Sof-Lab/Home_Lab/blob/main/Linux/Ldap/results/users.png)

А так же список подключенных к ldap хостов:

![Image alt](https://github.com/Sof-Lab/Home_Lab/blob/main/Linux/Ldap/results/hosts.png)
