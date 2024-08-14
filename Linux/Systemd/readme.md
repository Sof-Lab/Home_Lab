# Vagrant стeнд для работы с systemd

## Описание задачи

1. Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/default).
2. Установить spawn-fcgi и создать unit-файл (spawn-fcgi.sevice) с помощью переделки init-скрипта (https://gist.github.com/cea2k/1318020).
3. Доработать unit-файл Nginx (nginx.service) для запуска нескольких инстансов сервера с разными конфигурационными файлами одновременно.


## Выполнение

*Лабораторный стенд развёрнут на хосте с Windows + WSL2. На Windows установлены Vagrant и VirtualBox. Ansible установлен на WSL.*

*Все файлы для vagrant располагаются в директории windows, у меня это - D:\VBox_Projects\systemd. Команды для работы с vagrant запускаются из той же директории.*

*Все файлы для ansible располагаются в директории wsl, у меня это - /home/sof/otus_labs/systemd. Команды для работы с ansible звпускаются из той же директории.*

При помощи команды vagrant up развернута вм.
При помощи команды  ansible-playbook systemd.yml реализованы настройки.
Вывод ansible-playbook systemd.yml:

```console
PLAY [WSL localhost copy private_key] **************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************
ok: [wsl]

TASK [Create directory for private_key] ************************************************************************************
ok: [wsl]

TASK [Copy private_key file] ***********************************************************************************************
changed: [wsl]

TASK [Change permissions for private_key] **********************************************************************************
ok: [wsl]

PLAY [Configure systemd server] ********************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************
ok: [systemd]

TASK [Default config for service] ******************************************************************************************
changed: [systemd]

TASK [Create test log file] ************************************************************************************************
changed: [systemd]

TASK [Create script] *******************************************************************************************************
changed: [systemd]

TASK [Change permissions for watchlog.sh] **********************************************************************************
changed: [systemd]

TASK [Create unit for service] *********************************************************************************************
changed: [systemd]

TASK [Create unit for timer] ***********************************************************************************************
changed: [systemd]

TASK [Start timer] *********************************************************************************************************
changed: [systemd]

TASK [install spawn-fcgi] **************************************************************************************************
changed: [systemd]

TASK [Create directory for spawn-fcgi] *************************************************************************************
changed: [systemd]

TASK [Create config for spawn-fcgi] ****************************************************************************************
changed: [systemd]

TASK [Create unit for spawn-fcgi] ******************************************************************************************
changed: [systemd]

TASK [Start spawn-fcgi] ****************************************************************************************************
changed: [systemd]

TASK [install nginx] *******************************************************************************************************
changed: [systemd]

TASK [Create config for nginx service] *************************************************************************************
changed: [systemd]

TASK [Create config for nginx first] ***************************************************************************************
changed: [systemd]

TASK [Create config for nginx second] **************************************************************************************
changed: [systemd]

TASK [Start nginx first] ***************************************************************************************************
changed: [systemd]

TASK [Start nginx second] **************************************************************************************************
changed: [systemd]

PLAY [Check results] *******************************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************
ok: [systemd]

TASK [Check watchlog.service] **********************************************************************************************
changed: [systemd]

TASK [debug] ***************************************************************************************************************
ok: [systemd] => {
    "msg": [
        "Aug 14 19:07:47 ubuntu2204 kernel: [    8.410648] systemd[1]: Started Forward Password Requests to Wall Directory Watch.",
        "Aug 14 19:10:14 ubuntu2204 root: Wed Aug 14 07:10:14 PM UTC 2024: I found word, Master!",
        "Aug 14 19:10:48 ubuntu2204 root: Wed Aug 14 07:10:48 PM UTC 2024: I found word, Master!",
        "Aug 14 19:11:18 ubuntu2204 root: Wed Aug 14 07:11:18 PM UTC 2024: I found word, Master!",
        "Aug 14 19:11:20 ubuntu2204 python3[12444]: ansible-ansible.legacy.command Invoked with _raw_params=tail -n 1000 /var/log/syslog  | grep word _uses_shell=True expand_argument_vars=True stdin_add_newline=True strip_empty_ends=True argv=None chdir=None executable=None creates=None removes=None stdin=None"
    ]
}

TASK [Check spawn-fcgi] ****************************************************************************************************
changed: [systemd]

TASK [debug] ***************************************************************************************************************
ok: [systemd] => {
    "msg": [
        "● spawn-fcgi.service - Spawn-fcgi startup service by Otus",
        "     Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; enabled; vendor preset: enabled)",
        "     Active: active (running) since Wed 2024-08-14 19:11:03 UTC; 17s ago",
        "   Main PID: 11296 (php-cgi)",
        "      Tasks: 33 (limit: 1013)",
        "     Memory: 14.2M",
        "        CPU: 18ms",
        "     CGroup: /system.slice/spawn-fcgi.service",
        "             ├─11296 /usr/bin/php-cgi",
        "             ├─11297 /usr/bin/php-cgi",
        "             ├─11298 /usr/bin/php-cgi",
        "             ├─11299 /usr/bin/php-cgi",
        "             ├─11300 /usr/bin/php-cgi",
        "             ├─11301 /usr/bin/php-cgi",
        "             ├─11302 /usr/bin/php-cgi",
        "             ├─11303 /usr/bin/php-cgi",
        "             ├─11304 /usr/bin/php-cgi",
        "             ├─11305 /usr/bin/php-cgi",
        "             ├─11306 /usr/bin/php-cgi",
        "             ├─11307 /usr/bin/php-cgi",
        "             ├─11308 /usr/bin/php-cgi",
        "             ├─11309 /usr/bin/php-cgi",
        "             ├─11310 /usr/bin/php-cgi",
        "             ├─11311 /usr/bin/php-cgi",
        "             ├─11312 /usr/bin/php-cgi",
        "             ├─11313 /usr/bin/php-cgi",
        "             ├─11314 /usr/bin/php-cgi",
        "             ├─11315 /usr/bin/php-cgi",
        "             ├─11316 /usr/bin/php-cgi",
        "             ├─11317 /usr/bin/php-cgi",
        "             ├─11318 /usr/bin/php-cgi",
        "             ├─11319 /usr/bin/php-cgi",
        "             ├─11320 /usr/bin/php-cgi",
        "             ├─11321 /usr/bin/php-cgi",
        "             ├─11322 /usr/bin/php-cgi",
        "             ├─11323 /usr/bin/php-cgi",
        "             ├─11324 /usr/bin/php-cgi",
        "             ├─11325 /usr/bin/php-cgi",
        "             ├─11326 /usr/bin/php-cgi",
        "             ├─11327 /usr/bin/php-cgi",
        "             └─11328 /usr/bin/php-cgi",
        "",
        "Aug 14 19:11:03 systemd systemd[1]: Started Spawn-fcgi startup service by Otus.",
        "Aug 14 19:11:10 systemd systemd[1]: /etc/systemd/system/spawn-fcgi.service:7: PIDFile= references a path below legacy directory /var/run/, updating /var/run/spawn-fcgi.pid → /run/spawn-fcgi.pid; please update the unit file accordingly.",
        "Aug 14 19:11:10 systemd systemd[1]: /etc/systemd/system/spawn-fcgi.service:7: PIDFile= references a path below legacy directory /var/run/, updating /var/run/spawn-fcgi.pid → /run/spawn-fcgi.pid; please update the unit file accordingly.",
        "Aug 14 19:11:11 systemd systemd[1]: /etc/systemd/system/spawn-fcgi.service:7: PIDFile= references a path below legacy directory /var/run/, updating /var/run/spawn-fcgi.pid → /run/spawn-fcgi.pid; please update the unit file accordingly.",
        "Aug 14 19:11:17 systemd systemd[1]: /etc/systemd/system/spawn-fcgi.service:7: PIDFile= references a path below legacy directory /var/run/, updating /var/run/spawn-fcgi.pid → /run/spawn-fcgi.pid; please update the unit file accordingly.",
        "Aug 14 19:11:18 systemd systemd[1]: /etc/systemd/system/spawn-fcgi.service:7: PIDFile= references a path below legacy directory /var/run/, updating /var/run/spawn-fcgi.pid → /run/spawn-fcgi.pid; please update the unit file accordingly."
    ]
}

TASK [Check nginx count ports] *********************************************************************************************
changed: [systemd]

TASK [debug] ***************************************************************************************************************
ok: [systemd] => {
    "msg": [
        "tcp   LISTEN 0      511           0.0.0.0:9001      0.0.0.0:*    users:((\"nginx\",pid=12294,fd=6),(\"nginx\",pid=12293,fd=6))
                          ",
        "tcp   LISTEN 0      511           0.0.0.0:9002      0.0.0.0:*    users:((\"nginx\",pid=12352,fd=6),(\"nginx\",pid=12351,fd=6))
                          "
    ]
}

TASK [Check nginx count services] ******************************************************************************************
changed: [systemd]

TASK [debug] ***************************************************************************************************************
ok: [systemd] => {
    "msg": [
        "  12524 pts/1    S+     0:00                              \\_ /bin/sh -c ps afx | grep nginx",
        "  12526 pts/1    S+     0:00                                  \\_ grep nginx",
        "  12293 ?        Ss     0:00 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx-first.conf -g daemon on; master_process on;",
        "  12294 ?        S      0:00  \\_ nginx: worker process",
        "  12351 ?        Ss     0:00 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx-second.conf -g daemon on; master_process on;",
        "  12352 ?        S      0:00  \\_ nginx: worker process"
    ]
}

PLAY RECAP *****************************************************************************************************************
systemd                    : ok=28   changed=22   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
wsl                        : ok=4    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

```

## Проверка результатов

В выводе playbook TASK [Check watchlog.service] найдены требуемые логи вида "I found word, Master!" - выполнено.

В выводе playbook TASK [Check spawn-fcgi] статус запущенного spawn-fcgi - выполнено.

В выводе playbook TASK [Check nginx count ports]  и TASK [Check nginx count services] видно, что одновременно запущено два nginx - выполнено.