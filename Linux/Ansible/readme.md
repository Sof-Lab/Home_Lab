# Vagrant-Ansible стeнд для установки и настройки nginx.

## Описание задачи

1. Запустить ВМ с помощью Vagrant.
2. Развернуть nginx на ВМ с помощью Ansible.

*Лабораторный стенд развёрнут на хосте с Windows + WSL2. На Windows установлены Vagrant и VirtualBox. Ansible установлен на WSL.*

*Все файлы для vagrant располагаются в директории windows, у меня это - D:\VBox_Projects\ansible. Команды для работы с vagrant запускаются из той же директории.*

*Все файлы для ansible располагаются в директории wsl, у меня это - /home/sof/for_ansible. Команды для работы с ansible звпускаются из той же директории.*

## Выполнение

### 1. Запуск ВМ с помощью Vagrantfile.

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

### 2. Подготовка к работе с ansible.

В файле staging/hosts.yaml прописан localhost для выполнения команд в wsl.

Проверка доступа к localhost от ansible:

```console
$ ansible wsl -m ping
wsl | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```
Это требуется, чтобы скопировать ключ private_key для подключения к ВМ из директории windows в директорию wsl.

Подключение к nginx прописано через хост windows, так как напрямую из wsl ВМ на хостовой машине недоступны.
Используется дополнительно проброшенный порт `ssh-for-wsl`.

В ansible_private_key_file нужно указать директорию wsl, куда планируется скопировать private_key.
Копирование ключа настраивается в nginx.yaml.

### 3. Настройка nginx при помощи ansible.

Запуск Playbook nginx.yml.

```console
$ ansible-playbook nginx.yml

PLAY [WSL localhost copy private_key for ansible] **********************************************************

TASK [Gathering Facts] *************************************************************************************
ok: [wsl]

TASK [Create directory for private_key] ********************************************************************
changed: [wsl]

TASK [Copy private_key file] *******************************************************************************
changed: [wsl]

TASK [Change permissions for private_key] ******************************************************************
changed: [wsl]

PLAY [NGINX | Install and configure NGINX] *****************************************************************

TASK [Gathering Facts] *************************************************************************************
ok: [nginx]

TASK [Add epel-release] ************************************************************************************
changed: [nginx]

TASK [update] **********************************************************************************************
changed: [nginx]

TASK [NGINX | Install NGINX] *******************************************************************************
changed: [nginx]

TASK [NGINX | Create NGINX config file from template] ******************************************************
changed: [nginx]

RUNNING HANDLER [restart nginx] ****************************************************************************
changed: [nginx]

RUNNING HANDLER [reload nginx] *****************************************************************************
changed: [nginx]

PLAY RECAP *************************************************************************************************
nginx                      : ok=7    changed=6    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
wsl                        : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
Проверка статуса nginx:

```console
[vagrant@nginx ~]$ systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Sat 2024-04-06 16:02:14 UTC; 15s ago
  Process: 15173 ExecReload=/usr/sbin/nginx -s reload (code=exited, status=0/SUCCESS)
  Process: 15093 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 15091 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 15090 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 15095 (nginx)
   CGroup: /system.slice/nginx.service
           ├─15095 nginx: master process /usr/sbin/nginx
           └─15174 nginx: worker process
```

Проверка доступа по порту 8080:

```console
$ ansible nginx -m command -a "curl http://192.168.11.150:8080"
nginx | CHANGED | rc=0 >>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <title>Welcome to CentOS</title>
  <style rel="stylesheet" type="text/css">

        html {
...
```
