# Vagrant-стенд c PAM

## Описание задачи

Запретить всем пользователям кроме группы admin логин в выходные (суббота и воскресенье), без учета праздников

## Выполнение

*Лабораторный стенд развёрнут на хосте с Windows + WSL2. На Windows установлены Vagrant и VirtualBox. Ansible установлен на WSL.*

*Все файлы для vagrant располагаются в директории windows (win_directory), у меня это - D:\VBox_Projects\pam\. Команды для работы с vagrant запускаются из той же директории.*

*Все файлы для ansible располагаются в директории wsl (wsl_directory), у меня это - /home/sof/sof/otus_labs/pam/. Команды для работы с ansible звпускаются из той же директории.*

### 1. Запуск ВМ с помощью vagrant.
Предложенный в методичке Vagrantfile дополнен:
`sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf`.

Для доступа к ВМ из wsl в Vagrantfile прописан дополнительный проброс порта `ssh-for-wsl`.
В нём нужно указать ip-адрес хоста и желаемый порт ssh для подключения:
```
:wslp => "2228", # Порт для подключения по ssh из WSL
:hostip => "192.168.1.8", #  # Ip-адрес Windows-хоста.
```

### 2. Настройка ВМ с помощью ansible.

В файле staging/hosts.yaml нужно заполнить переменные для выполнения настройки ВМ:
```
all:
  vars: 
    vm_name: pam        		   # имя ВМ в VB
    host_ip: 192.168.1.8   		 # Ip-адрес Windows-хоста
    vm_port: 2228         		  # Порт для подключения по ssh
    dir_vagrant: /mnt/d/VBox_Projects/pam/     # Директория wsl, где расположены файлы windows-хоста для работы с vagrant
    dir_wsl: /home/sof/otus_labs/pam/       # Директория wsl, где расположены файлы ansible
```

В файле staging/hosts.yaml прописан localhost для выполнения команд в wsl.
Это требуется, чтобы скопировать ключ private_key для подключения к ВМ из директории windows в директорию wsl.

Запуск Playbook pam.yml.

```console
~/otus_labs/pam$ ansible-playbook pam.yml

PLAY [WSL localhost copy private_key] **************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************
ok: [wsl]

TASK [Create directory for private_key] ************************************************************************************
changed: [wsl]

TASK [Copy private_key file] ***********************************************************************************************
changed: [wsl]

TASK [Change permissions for private_key] **********************************************************************************
changed: [wsl]

PLAY [Configure vbox_vm] ***************************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************
ok: [lab_vm]

TASK [Add group of users] **************************************************************************************************
ok: [lab_vm]

TASK [Add user otus] *******************************************************************************************************
changed: [lab_vm]

TASK [Add user otusadm] ****************************************************************************************************
changed: [lab_vm]

TASK [Add user root in group admin] ****************************************************************************************
changed: [lab_vm]

TASK [Add user vagrant in group admin] *************************************************************************************
changed: [lab_vm]

TASK [Check admin users] ***************************************************************************************************
changed: [lab_vm]

TASK [debug] ***************************************************************************************************************
ok: [lab_vm] => {
    "msg": [
        "admin:x:118:otusadm,root,vagrant"
    ]
}

TASK [Add script login.sh] *************************************************************************************************
changed: [lab_vm]

TASK [Change permissions for login.sh] *************************************************************************************
changed: [lab_vm]

TASK [Add path to script in pam config] ************************************************************************************
changed: [lab_vm]

PLAY RECAP *****************************************************************************************************************
lab_vm                     : ok=11   changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
wsl                        : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### 3. Проверка результатов.

Попытка подключиться под пользователем otus:

```console
~$ ssh otus@192.168.57.10

otus@192.168.57.10's password:
Permission denied, please try again.
```

Не удалось подключиться, что верно, так как сегодня воскресенье.

Попытка подключиться под пользователем otusadm:

```console
~$ ssh otusadm@192.168.57.10

otusadm@192.168.57.10's password:
Welcome to Ubuntu 22.04.4 LTS (GNU/Linux 5.15.0-119-generic x86_64)

$ date
Sun Sep  8 15:46:36 UTC 2024
$ exit
Connection to 192.168.57.10 closed.
```
Успешно.