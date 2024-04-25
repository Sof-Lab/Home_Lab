# Vagrant стeнд для работы с mdadm

## Описание задачи

1. Запустить ВМ.
2. Собрать RAID6.
3. Сломать/Починить RAID.
4. Создать GPT раздел и 5 партиций, смонтировать их на диск.
5. Прописать собранный RAID в конф, чтобы RAID собирался при загрузке.


## Выполнение

### 1. Запуск ВМ.

Запущена ВМ при помощи Vagrantfile.

### 2. Собрать RAID6.

Установка mdadm:

```console
sudo su
```
```console
yum install mdadm -y
```

Проверка дисков:

```console
lsblk
```
...
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk
└─sda1   8:1    0   40G  0 part /
sdb      8:16   0  250M  0 disk
sdc      8:32   0  250M  0 disk
sdd      8:48   0  250M  0 disk
sde      8:64   0  250M  0 disk
sdf      8:80   0  250M  0 disk
...

Зануление суперблоков:

```console
mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
```

Создание RAID6:

```console
mdadm --create --verbose /dev/md0 -l 6 -n 5 /dev/sd{b,c,d,e,f}
```

Проверка RAID:

```console
mdadm -D /dev/md0
```
...
/dev/md0:
           Version : 1.2
     Creation Time : Tue Apr 23 18:12:17 2024
        Raid Level : raid6
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 5
     Total Devices : 5
       Persistence : Superblock is persistent

       Update Time : Tue Apr 23 18:12:47 2024
             State : clean
    Active Devices : 5
   Working Devices : 5
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : raid:0  (local to host raid)
              UUID : 9860fa41:cdd1ed13:16522d92:25d3cca7
            Events : 17

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       3       8       64        3      active sync   /dev/sde
       4       8       80        4      active sync   /dev/sdf
...

Создание конфиг файла mdadm.conf:

```console
mkdir /etc/mdadm/
```
```console
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
```
```console
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
```

Проверка дисков:

```console
lsblk
```
...
NAME   MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
sda      8:0    0   40G  0 disk
└─sda1   8:1    0   40G  0 part  /
sdb      8:16   0  250M  0 disk
└─md0    9:0    0  744M  0 raid6
sdc      8:32   0  250M  0 disk
└─md0    9:0    0  744M  0 raid6
sdd      8:48   0  250M  0 disk
└─md0    9:0    0  744M  0 raid6
sde      8:64   0  250M  0 disk
└─md0    9:0    0  744M  0 raid6
sdf      8:80   0  250M  0 disk
└─md0    9:0    0  744M  0 raid6
...

### 3. Сломать/Починить RAID.

Искусственная поломка диска:

```console
mdadm /dev/md0 --fail /dev/sdf
```

Проверка RAID:

```console
mdadm -D /dev/md0
```
...
/dev/md0:
           Version : 1.2
     Creation Time : Tue Apr 23 18:12:17 2024
        Raid Level : raid6
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 5
     Total Devices : 5
       Persistence : Superblock is persistent

       Update Time : Tue Apr 23 18:19:50 2024
             State : clean, degraded
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 1
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : raid:0  (local to host raid)
              UUID : 9860fa41:cdd1ed13:16522d92:25d3cca7
            Events : 19

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       3       8       64        3      active sync   /dev/sde
       -       0        0        4      removed

       4       8       80        -      faulty   /dev/sdf
...

Удаление сломанного диска из массива:

```console
mdadm /dev/md0 --remove /dev/sdf
```

Добавление диска в массив:

```console
mdadm /dev/md0 --add /dev/sdf
```

Проверка RAID:

```console
mdadm -D /dev/md0
```
...
/dev/md0:
           Version : 1.2
     Creation Time : Tue Apr 23 18:12:17 2024
        Raid Level : raid6
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 5
     Total Devices : 5
       Persistence : Superblock is persistent

       Update Time : Tue Apr 23 18:27:52 2024
             State : clean, degraded, recovering
    Active Devices : 4
   Working Devices : 5
    Failed Devices : 0
     Spare Devices : 1

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

    Rebuild Status : 5% complete

              Name : raid:0  (local to host raid)
              UUID : 9860fa41:cdd1ed13:16522d92:25d3cca7
            Events : 44

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       3       8       64        3      active sync   /dev/sde
       5       8       80        4      spare rebuilding   /dev/sdf
...

### 4. Создать GPT раздел и 5 партиций, смонтировать их на диск.

Создание GPT раздела:


`parted -s /dev/md0 mklabel gpt`


Создание партиций:

```console
parted -s /dev/md0 mkpart primery ext4 0% 20%
```
```console
parted -s /dev/md0 mkpart primery ext4 20% 40%
```
```console
parted -s /dev/md0 mkpart primery ext4 40% 60%
```
```console
parted -s /dev/md0 mkpart primery ext4 60% 80%
```
```console
parted -s /dev/md0 mkpart primery ext4 80% 100%
```

Создание файловой системы на партициях:

```console
for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
```

Создание каталогов и монтирование их к партициям:

```console
mkdir -p /raid/part{1,2,3,4,5}
```
```console
for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done
```

Результат:

```console
lsblk
```
```
NAME      MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
sda         8:0    0    40G  0 disk
└─sda1      8:1    0    40G  0 part  /
sdb         8:16   0   250M  0 disk
└─md0       9:0    0   744M  0 raid6
  ├─md0p1 259:0    0   147M  0 md    /raid/part1
  ├─md0p2 259:1    0 148.5M  0 md    /raid/part2
  ├─md0p3 259:2    0   150M  0 md    /raid/part3
  ├─md0p4 259:3    0 148.5M  0 md    /raid/part4
  └─md0p5 259:4    0   147M  0 md    /raid/part5
sdc         8:32   0   250M  0 disk
└─md0       9:0    0   744M  0 raid6
  ├─md0p1 259:0    0   147M  0 md    /raid/part1
  ├─md0p2 259:1    0 148.5M  0 md    /raid/part2
  ├─md0p3 259:2    0   150M  0 md    /raid/part3
  ├─md0p4 259:3    0 148.5M  0 md    /raid/part4
  └─md0p5 259:4    0   147M  0 md    /raid/part5
sdd         8:48   0   250M  0 disk
└─md0       9:0    0   744M  0 raid6
  ├─md0p1 259:0    0   147M  0 md    /raid/part1
  ├─md0p2 259:1    0 148.5M  0 md    /raid/part2
  ├─md0p3 259:2    0   150M  0 md    /raid/part3
  ├─md0p4 259:3    0 148.5M  0 md    /raid/part4
  └─md0p5 259:4    0   147M  0 md    /raid/part5
sde         8:64   0   250M  0 disk
└─md0       9:0    0   744M  0 raid6
  ├─md0p1 259:0    0   147M  0 md    /raid/part1
  ├─md0p2 259:1    0 148.5M  0 md    /raid/part2
  ├─md0p3 259:2    0   150M  0 md    /raid/part3
  ├─md0p4 259:3    0 148.5M  0 md    /raid/part4
  └─md0p5 259:4    0   147M  0 md    /raid/part5
sdf         8:80   0   250M  0 disk
└─md0       9:0    0   744M  0 raid6
  ├─md0p1 259:0    0   147M  0 md    /raid/part1
  ├─md0p2 259:1    0 148.5M  0 md    /raid/part2
  ├─md0p3 259:2    0   150M  0 md    /raid/part3
  ├─md0p4 259:3    0 148.5M  0 md    /raid/part4
  └─md0p5 259:4    0   147M  0 md    /raid/part5
```

```console
df -h
```
...
Filesystem      Size  Used Avail Use% Mounted on
devtmpfs        489M     0  489M   0% /dev
tmpfs           496M     0  496M   0% /dev/shm
tmpfs           496M  6.7M  489M   2% /run
tmpfs           496M     0  496M   0% /sys/fs/cgroup
/dev/sda1        40G  4.5G   36G  12% /
tmpfs           100M     0  100M   0% /run/user/1000
/dev/md0p1      139M  1.6M  127M   2% /raid/part1
/dev/md0p2      140M  1.6M  128M   2% /raid/part2
/dev/md0p3      142M  1.6M  130M   2% /raid/part3
/dev/md0p4      140M  1.6M  128M   2% /raid/part4
/dev/md0p5      139M  1.6M  127M   2% /raid/part5
...

### 5. Прописать собранный RAID в конф, чтобы RAID собирался при загрузке.

```console
for i in $(seq 1 5); do echo /dev/md0p$i /raid/part$i ext4 defaults 0 0 >> /etc/fstab; done
```

Результат:

```console
cat /etc/fstab
```
```console
#
# /etc/fstab
# Created by anaconda on Thu Apr 30 22:04:55 2020
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
UUID=1c419d6c-5064-4a2b-953c-05b2c67edb15 /                       xfs     defaults        0 0
/swapfile none swap defaults 0 0
#VAGRANT-BEGIN
# The contents below are automatically generated by Vagrant. Do not modify.
#VAGRANT-END
/dev/md0p1 /raid/part1 ext4 defaults 0 0
/dev/md0p2 /raid/part2 ext4 defaults 0 0
/dev/md0p3 /raid/part3 ext4 defaults 0 0
/dev/md0p4 /raid/part4 ext4 defaults 0 0
/dev/md0p5 /raid/part5 ext4 defaults 0 0
```