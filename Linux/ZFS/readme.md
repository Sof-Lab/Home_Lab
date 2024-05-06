# Vagrant стeнд для работы с ZFS

## Описание задачи

1. Запустить ВМ на образе centos/7 - v. 2004.01.
2. Определить алгоритм с наилучшим сжатием.
3. Определить настройки пула.
4. Работа со снапшотами.

## Выполнение

### 1. Запуск ВМ.

Скачен требуемый образ.
При помощи команды образ добавлен в Vagrant:
```console
vagrant box add --name 'centos/7-2004.01' CentOS-7-2004_01.VirtualBox.box
```
Запущена ВМ при помощи Vagrantfile.

### 2. Определение алгоритма с наилучшим сжатием.

```console
sudo -i
```
Создание 4х пулов zafs для применения различных методов сжатия:
```console
zpool create otus1 mirror /dev/sd{b,c}
zpool create otus2 mirror /dev/sd{d,e}
zpool create otus3 mirror /dev/sd{f,g}
zpool create otus4 mirror /dev/sd{h,i}
```
Проверка результата:
```console
lsblk
```
```
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   40G  0 disk
└─sda1   8:1    0   40G  0 part /
sdb      8:16   0  512M  0 disk
├─sdb1   8:17   0  502M  0 part
└─sdb9   8:25   0    8M  0 part
sdc      8:32   0  512M  0 disk
├─sdc1   8:33   0  502M  0 part
└─sdc9   8:41   0    8M  0 part
sdd      8:48   0  512M  0 disk
├─sdd1   8:49   0  502M  0 part
└─sdd9   8:57   0    8M  0 part
sde      8:64   0  512M  0 disk
├─sde1   8:65   0  502M  0 part
└─sde9   8:73   0    8M  0 part
sdf      8:80   0  512M  0 disk
├─sdf1   8:81   0  502M  0 part
└─sdf9   8:89   0    8M  0 part
sdg      8:96   0  512M  0 disk
├─sdg1   8:97   0  502M  0 part
└─sdg9   8:105  0    8M  0 part
sdh      8:112  0  512M  0 disk
├─sdh1   8:113  0  502M  0 part
└─sdh9   8:121  0    8M  0 part
sdi      8:128  0  512M  0 disk
├─sdi1   8:129  0  502M  0 part
└─sdi9   8:137  0    8M  0 part
```
```console
zpool list
```
```
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus2   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus3   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus4   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
```
```console
zpool status
```
```
  pool: otus1
 state: ONLINE
  scan: none requested
config:

        NAME        STATE     READ WRITE CKSUM
        otus1       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdb     ONLINE       0     0     0
            sdc     ONLINE       0     0     0

errors: No known data errors

  pool: otus2
 state: ONLINE
  scan: none requested
config:

        NAME        STATE     READ WRITE CKSUM
        otus2       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdd     ONLINE       0     0     0
            sde     ONLINE       0     0     0

errors: No known data errors

  pool: otus3
 state: ONLINE
  scan: none requested
config:

        NAME        STATE     READ WRITE CKSUM
        otus3       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdf     ONLINE       0     0     0
            sdg     ONLINE       0     0     0

errors: No known data errors

  pool: otus4
 state: ONLINE
  scan: none requested
config:

        NAME        STATE     READ WRITE CKSUM
        otus4       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            sdh     ONLINE       0     0     0
            sdi     ONLINE       0     0     0

errors: No known data errors
```
Добавление разных алгоритмов сжатия в каждую файловую систему из созданных в предыдущем шаге:
```console
zfs set compression=lzjb otus1
zfs set compression=lz4 otus2
zfs set compression=gzip-9 otus3
zfs set compression=zle otus4
```
Проверка результата:
```console
zfs get all | grep compression
```
```
otus1  compression           lzjb                   local
otus2  compression           lz4                    local
otus3  compression           gzip-9                 local
otus4  compression           zle                    local
```
Сжатие файлов будет работать только с файлами, которые были добавлены после включение настройки сжатия. 
Скачивание одного файла во все пулы:
```console
for i in {1..4}; do wget -P /otus$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done
```
Проверка результата:
```console
ls -l /otus*
```
```
/otus1:
total 22077
-rw-r--r--. 1 root root 41043469 May  2 07:54 pg2600.converter.log

/otus2:
total 17998
-rw-r--r--. 1 root root 41043469 May  2 07:54 pg2600.converter.log

/otus3:
total 10962
-rw-r--r--. 1 root root 41043469 May  2 07:54 pg2600.converter.log

/otus4:
total 40109
-rw-r--r--. 1 root root 41043469 May  2 07:54 pg2600.converter.log
```
```console
zfs list
```
```
NAME    USED  AVAIL     REFER  MOUNTPOINT
otus1  21.7M   330M     21.6M  /otus1
otus2  17.7M   334M     17.6M  /otus2
otus3  10.8M   341M     10.7M  /otus3
otus4  39.3M   313M     39.2M  /otus4
```
```console
zfs get all |grep compressratio | grep -v ref
```
```
otus1  compressratio         1.82x                  -
otus2  compressratio         2.23x                  -
otus3  compressratio         3.66x                  -
otus4  compressratio         1.00x                  -
```
Наибольшая степень сжатия у алгоритма gzip-9, который применен к пулу otus3.

### 3. Определение настроек пула.

Скачивание архива:
```console
wget -O archive.tar.gz --no-check-certificate 'https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download'
tar -xzvf archive.tar.gz
```
Проверка, можно ли импортировать каталог в пул:
```console
zpool import -d zpoolexport/
```
```
   pool: otus
     id: 6554193320433390805
  state: ONLINE
 action: The pool can be imported using its name or numeric identifier.
 config:

        otus                         ONLINE
          mirror-0                   ONLINE
            /root/zpoolexport/filea  ONLINE
            /root/zpoolexport/fileb  ONLINE
```
Импорт пула в ОС:
```console
zpool import -d zpoolexport/ otus
```
Проверка результата:
```console
zpool status
```
```
  pool: otus
 state: ONLINE
  scan: none requested
config:

        NAME                         STATE     READ WRITE CKSUM
        otus                         ONLINE       0     0     0
          mirror-0                   ONLINE       0     0     0
            /root/zpoolexport/filea  ONLINE       0     0     0
            /root/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors
```
Определение настроек:
```console
zfs get available otus
```
```
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -
```
```console
zfs get readonly otus
```
```
NAME  PROPERTY  VALUE   SOURCE
otus  readonly  off     default
```
```console
zfs get recordsize otus
```
```
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local
```
```console
zfs get compression otus
```
```
NAME  PROPERTY     VALUE     SOURCE
otus  compression  zle       local
```
```console
zfs get checksum otus
```
```
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local
```
```console
zfs get all otus
```
```
NAME  PROPERTY              VALUE                  SOURCE
otus  type                  filesystem             -
otus  creation              Fri May 15  4:00 2020  -
otus  used                  2.04M                  -
otus  available             350M                   -
otus  referenced            24K                    -
otus  compressratio         1.00x                  -
otus  mounted               yes                    -
otus  quota                 none                   default
otus  reservation           none                   default
otus  recordsize            128K                   local
otus  mountpoint            /otus                  default
otus  sharenfs              off                    default
otus  checksum              sha256                 local
otus  compression           zle                    local
otus  atime                 on                     default
otus  devices               on                     default
otus  exec                  on                     default
otus  setuid                on                     default
otus  readonly              off                    default
otus  zoned                 off                    default
otus  snapdir               hidden                 default
otus  aclinherit            restricted             default
otus  createtxg             1                      -
otus  canmount              on                     default
otus  xattr                 on                     default
otus  copies                1                      default
otus  version               5                      -
otus  utf8only              off                    -
otus  normalization         none                   -
otus  casesensitivity       sensitive              -
otus  vscan                 off                    default
otus  nbmand                off                    default
otus  sharesmb              off                    default
otus  refquota              none                   default
otus  refreservation        none                   default
otus  guid                  14592242904030363272   -
otus  primarycache          all                    default
otus  secondarycache        all                    default
otus  usedbysnapshots       0B                     -
otus  usedbydataset         24K                    -
otus  usedbychildren        2.01M                  -
otus  usedbyrefreservation  0B                     -
otus  logbias               latency                default
otus  objsetid              54                     -
otus  dedup                 off                    default
otus  mlslabel              none                   default
otus  sync                  standard               default
otus  dnodesize             legacy                 default
otus  refcompressratio      1.00x                  -
otus  written               24K                    -
otus  logicalused           1020K                  -
otus  logicalreferenced     12K                    -
otus  volmode               default                default
otus  filesystem_limit      none                   default
otus  snapshot_limit        none                   default
otus  filesystem_count      none                   default
otus  snapshot_count        none                   default
otus  snapdev               hidden                 default
otus  acltype               off                    default
otus  context               none                   default
otus  fscontext             none                   default
otus  defcontext            none                   default
otus  rootcontext           none                   default
otus  relatime              off                    default
otus  redundant_metadata    all                    default
otus  overlay               off                    default
otus  encryption            off                    default
otus  keylocation           none                   default
otus  keyformat             none                   default
otus  pbkdf2iters           0                      default
otus  special_small_blocks  0                      default
```

### 4. Работа со снапшотами.

Скачивание файла, указанного в задании:
```console
wget -O otus_task2.file --no-check-certificate https://drive.usercontent.google.com/download?id=1wgxjih8YZ-cqLqaZVa0lA3h3Y029c3oI&export=download
```
Восстановление из снапшота:
```console
zfs receive otus/test@today < otus_task2.file
```
Поиск искомого файла:
```console
find /otus/test -name "secret_message"
```
```
/otus/test/task1/file_mess/secret_message
```
Просмотр содержимого файла:
```console
cat /otus/test/task1/file_mess/secret_message
```
```
https://otus.ru/lessons/linux-hl/
```