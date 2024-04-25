# Vagrant стeнд для работы с mdadm

## Описание задачи

1. Vagrantfile, который сразу собирает систему с подключенным RAID5 и смонтированными разделами.

## Выполнение

### 1. Запуск ВМ.

Запущена ВМ при помощи Vagrantfile.

### 2. Результат.

```console
lsblk
```
```
NAME      MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
sda         8:0    0    40G  0 disk
└─sda1      8:1    0    40G  0 part  /
sdb         8:16   0   250M  0 disk
└─md5       9:5    0   744M  0 raid5
  ├─md5p1 259:0    0 370.5M  0 md    /raid5/part1
  └─md5p2 259:1    0 370.5M  0 md    /raid5/part2
sdc         8:32   0   250M  0 disk
└─md5       9:5    0   744M  0 raid5
  ├─md5p1 259:0    0 370.5M  0 md    /raid5/part1
  └─md5p2 259:1    0 370.5M  0 md    /raid5/part2
sdd         8:48   0   250M  0 disk
└─md5       9:5    0   744M  0 raid5
  ├─md5p1 259:0    0 370.5M  0 md    /raid5/part1
  └─md5p2 259:1    0 370.5M  0 md    /raid5/part2
sde         8:64   0   250M  0 disk
└─md5       9:5    0   744M  0 raid5
  ├─md5p1 259:0    0 370.5M  0 md    /raid5/part1
  └─md5p2 259:1    0 370.5M  0 md    /raid5/part2
```

```console
df -h
```
```
Filesystem      Size  Used Avail Use% Mounted on
devtmpfs        489M     0  489M   0% /dev
tmpfs           496M     0  496M   0% /dev/shm
tmpfs           496M  6.7M  489M   2% /run
tmpfs           496M     0  496M   0% /sys/fs/cgroup
/dev/sda1        40G  4.2G   36G  11% /
/dev/md5p1      351M  2.1M  327M   1% /raid5/part1
/dev/md5p2      351M  2.1M  327M   1% /raid5/part2
tmpfs           100M     0  100M   0% /run/user/1000
```

```console
sudo mdadm -D /dev/md5
```
```
/dev/md5:
           Version : 1.2
     Creation Time : Wed Apr 24 23:53:20 2024
        Raid Level : raid5
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 4
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Wed Apr 24 23:54:50 2024
             State : clean
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : raid-3:5  (local to host raid-3)
              UUID : 60a66b98:7c437560:8191d699:936bc831
            Events : 68

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       4       8       64        3      active sync   /dev/sde
```