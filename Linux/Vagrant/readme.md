# Vagrant-стенд для обновления ядра и создания образа системы.
============================================================================================================

------------------------------------------------------------------------------------------------------------
# Описание задачи

1. Запустить ВМ с помощью Vagrant.
2. Обновить ядро ОС из репозитория ELRepo.
3. Собрать ядро из исходников.

------------------------------------------------------------------------------------------------------------
# Выполнение

1. Запущены две ВМ с помощью Vagrantfile.
2. На ВМ kern_updt обновлено ядро при помощи действий:

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
$ make modules_install install

$ vi /etc/default/grub

...
GRUB_DEFAULT=0
...


$ grub2-mkconfig -o /boot/grub2/grub.cfg


$ uname -r
6.8.0
$ uname -a
Linux kern-new 6.8.0 #1 SMP PREEMPT_DYNAMIC Wed Mar 13 22:03:47 UTC 2024 x86_64 x86_64 x86_64 GNU/Linux
```