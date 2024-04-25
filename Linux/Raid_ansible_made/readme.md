# Vagrant-Ansible стeнд для работы с mdadm.

## Описание задачи

1. Запустить ВМ.
2. Собрать RAID10.
3. Создать GPT раздел и 2 партиции, смонтировать их на диск.
4. Прописать собранный RAID в конф, чтобы RAID собирался при загрузке.

> [!NOTE]
> Лабораторный стенд развёрнут на хосте с Windows + WSL2. На Windows установлены Vagrant и VirtualBox. Ansible установлен на WSL.
> Все файлы для vagrant располагаются в директории windows, у меня это - D:\VBox_Projects\raid_2. Команды для работы с vagrant запускаются из той же директории.
> Все файлы для ansible располагаются в директории wsl, у меня это - /home/sof/otus_labs/raid_2. Команды для работы с ansible запускаются из той же директории.

## Выполнение

### 1. Запуск ВМ с помощью Vagrantfile.

Вывод команды `vagrant ssh-config`:

```
Host raid_2
  HostName 127.0.0.1
  User vagrant
  Port 2200
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile D:/VBox_Projects/raid_2/.vagrant/machines/raid_2/virtualbox/private_key
  IdentitiesOnly yes
  LogLevel FATAL
  PubkeyAcceptedKeyTypes +ssh-rsa
  HostKeyAlgorithms +ssh-rsa
```

Проверка дополнительно проброшенного порта `ssh-for-wsl` для доступа к ВМ из wsl:

![Image alt](https://github.com/Sof-Lab/Home_Lab/blob/main/Linux/Raid_ansible_made/%D0%9F%D1%80%D0%BE%D0%B1%D1%80%D0%BE%D1%81%20%D0%BF%D0%BE%D1%80%D1%82%D0%BE%D0%B2%20VirtualBox.png)

*192.168.1.6 - ip-адрес хост-машины Windows.*
*Именно эти параметры будут использованы для подключения к ВМ из wsl.*

### 2. Подготовка к работе с ansible.

В файле staging/hosts.yaml прописан localhost для выполнения команд в wsl.
Это требуется, чтобы скопировать ключ private_key для подключения к ВМ из директории windows в директорию wsl.

Подключение к вм прописано через хост windows, так как напрямую из wsl ВМ на хостовой машине недоступны.
Используется дополнительно проброшенный порт `ssh-for-wsl`.

В ansible_private_key_file (файл staging/hosts.yaml)нужно указать директорию wsl, куда планируется скопировать private_key.
Копирование ключа настраивается в raid.yaml.

### 3. Настройка RAID при помощи ansible.

Запуск Playbook raid.yml. Вывод результата:

```
TASK [debug] ***************************************************************************************************************
ok: [raid_2] => {
    "msg": [
        "/dev/md10:",
        "           Version : 1.2",
        "     Creation Time : Wed Apr 24 23:17:07 2024",
        "        Raid Level : raid10",
        "        Array Size : 507904 (496.00 MiB 520.09 MB)",
        "     Used Dev Size : 253952 (248.00 MiB 260.05 MB)",
        "      Raid Devices : 4",
        "     Total Devices : 4",
        "       Persistence : Superblock is persistent",
        "",
        "       Update Time : Wed Apr 24 23:17:12 2024",
        "             State : clean, resyncing ",
        "    Active Devices : 4",
        "   Working Devices : 4",
        "    Failed Devices : 0",
        "     Spare Devices : 0",
        "",
        "            Layout : near=2",
        "        Chunk Size : 512K",
        "",
        "Consistency Policy : resync",
        "",
        "     Resync Status : 4% complete",
        "",
        "              Name : raid-2:10  (local to host raid-2)",
        "              UUID : 912df7c2:6f334d1e:b2d27cac:86bbf40c",
        "            Events : 8",
        "",
        "    Number   Major   Minor   RaidDevice State",
        "       0       8       16        0      active sync set-A   /dev/sdb",
        "       1       8       32        1      active sync set-B   /dev/sdc",
        "       2       8       48        2      active sync set-A   /dev/sdd",
        "       3       8       64        3      active sync set-B   /dev/sde"
    ]
}

TASK [debug] ***************************************************************************************************************
ok: [raid_2] => {
    "msg": [
        "Filesystem      Size  Used Avail Use% Mounted on",
        "devtmpfs        489M     0  489M   0% /dev",
        "tmpfs           496M     0  496M   0% /dev/shm",
        "tmpfs           496M  6.7M  489M   2% /run",
        "tmpfs           496M     0  496M   0% /sys/fs/cgroup",
        "/dev/sda1        40G  4.6G   36G  12% /",
        "tmpfs           100M     0  100M   0% /run/user/1000",
        "/dev/md10p1     236M  2.1M  217M   1% /raid/part1",
        "/dev/md10p2     236M  2.1M  217M   1% /raid/part2"
    ]
}

TASK [debug] ***************************************************************************************************************
ok: [raid_2] => {
    "msg": [
        "NAME       MAJ:MIN RM  SIZE RO TYPE   MOUNTPOINT",
        "sda          8:0    0   40G  0 disk   ",
        "└─sda1       8:1    0   40G  0 part   /",
        "sdb          8:16   0  250M  0 disk   ",
        "└─md10       9:10   0  496M  0 raid10 ",
        "  ├─md10p1 259:0    0  247M  0 md     /raid/part1",
        "  └─md10p2 259:1    0  247M  0 md     /raid/part2",
        "sdc          8:32   0  250M  0 disk   ",
        "└─md10       9:10   0  496M  0 raid10 ",
        "  ├─md10p1 259:0    0  247M  0 md     /raid/part1",
        "  └─md10p2 259:1    0  247M  0 md     /raid/part2",
        "sdd          8:48   0  250M  0 disk   ",
        "└─md10       9:10   0  496M  0 raid10 ",
        "  ├─md10p1 259:0    0  247M  0 md     /raid/part1",
        "  └─md10p2 259:1    0  247M  0 md     /raid/part2",
        "sde          8:64   0  250M  0 disk   ",
        "└─md10       9:10   0  496M  0 raid10 ",
        "  ├─md10p1 259:0    0  247M  0 md     /raid/part1",
        "  └─md10p2 259:1    0  247M  0 md     /raid/part2"
    ]
}
```