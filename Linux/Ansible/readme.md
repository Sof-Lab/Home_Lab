# Vagrant-Ansible стeнд для установки и настройки nginx.

## Описание задачи

1. Запустить ВМ с помощью Vagrant.
2. Развернуть nginx на ВМ с помощью Ansible.

*Лабораторный стенд развёрнут на хосте с Windows + WSL2. На Windows установлены Vagrant и VirtualBox. Ansible установлен на WSL.*

## Выполнение

### 1. Запущена ВМ с помощью Vagrantfile.

Запускается в Windows из директории, где расположены файлы Vagrant.
У меня это - D:\VBox_Projects\ansible.

Вывод команды `vagrant ssh-config`:

```console
$ vagrant ssh-config
Host nginx
  HostName 127.0.0.1
  User vagrant
  Port 2222
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile D:/VBox_Projects/ansible/.vagrant/machines/nginx/virtualbox/private_key
  IdentitiesOnly yes
  LogLevel FATAL
  PubkeyAcceptedKeyTypes +ssh-rsa
  HostKeyAlgorithms +ssh-rsa
```

Проверка дополнительно проброшенного порта `ssh-for-wsl` для доступа к ВМ из wsl:

![Image alt](https://github.com/Sof-Lab/Home_Lab/blob/main/Linux/Ansible/%D0%9F%D1%80%D0%BE%D0%B1%D1%80%D0%BE%D1%81%20%D0%BF%D0%BE%D1%80%D1%82%D0%BE%D0%B2%20VirtualBox.png)
*192.168.1.6 - ip-адрес хост-машины Windows.*
*Именно эти параметры будут использованы для подключения к ВМ из wsl.*

### 2. Созданы файлы hosts.yaml и ansible.cfg.

Файлы расположены в директории wsl для работы с Ansible.
У меня это - /home/sof/for_ansible.
В hosts.yaml прописан localhost для выполнения команд в wsl (для переноса private_key из директории Windows в директорию Ansible).
Подключение к nginx прописано через хост Windows, так как напрямую из wsl ВМ на хостовой машине недоступны.
Используется дополнительно проброшенный порт.

Проверка доступа nginx и localhost из wsl:

```console
$ ansible wsl -m ping
wsl | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
$ ansible nginx -m ping
nginx | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"


Проверка

```console
$ uname -r
3.10.0-1127.el7.x86_64

$ sudo yum -y install https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
$ sudo yum --enablerepo elrepo-kernel install kernel-ml
$ sudo grub2-mkconfig -o /boot/grub2/grub.cfg
$ sudo grub2-set-default 0
$ sudo reboot

$ uname -r
6.7.9-1.el7.elrepo.x86_64
```

3. На ВМ kern_new собрано ядро из исходников при помощи действий:

```console
$ uname -r
3.10.0-1127.el7.x86_64

$ sudo yum install -y ncurses-devel make gcc bc bison flex elfutils-libelf-devel openssl-devel grub2 wget
$ wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.8.tar.xz
$ sudo tar -xvf linux-6.8.tar.xz -C /usr/src
$ cd /usr/src/linux-6.8/
$ sudo yum -y groupinstall "Development Tools"
```

------------------------------------------------------------------------------------------------------------
На данном этапе потребовалось обновить gcc

```console
$ gcc --version
gcc (GCC) 4.8.5 20150623 (Red Hat 4.8.5-44)

$ sudo yum install -y centos-release-scl 
$ sudo yum install -y devtoolset-8
$ scl enable devtoolset-8 bash

$ gcc --version
gcc (GCC) 8.3.1 20190311 (Red Hat 8.3.1-3)
```
------------------------------------------------------------------------------------------------------------

```console
$ sudo make oldconfig
$ sudo make
$ sudo make modules_install install

$ sudo vi /etc/default/grub

...
GRUB_DEFAULT=0
...

$ sudo grub2-mkconfig -o /boot/grub2/grub.cfg
$ sudo reboot

$ uname -r
6.8.0
$ uname -a
Linux kern-new 6.8.0 #1 SMP PREEMPT_DYNAMIC Thu Mar 14 20:55:10 UTC 2024 x86_64 x86_64 x86_64 GNU/Linux
```