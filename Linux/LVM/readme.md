# Vagrant стeнд для работы с LVM

## Описание задачи

1. Запустить ВМ на образе centos/7 - v. 1804.2
2. Уменьшить том под / до 8G.
3. Выделить том под /var - сделать в mirror.
4. Выделить том под /home.
5. /home - сделать том для снапшотов. Работа со снэпшотами:
- сгенерить файлы в /home/;
- снять снапшот;
- удалить часть файлов;
- восстановится со снапшота.
6. Прописать монтирование в fstab (выполняется в п.3,4,5).

## Выполнение

### 1. Запуск ВМ.

Скачен требуемый образ.
При помощи команды образ добавлен в Vagrant:
```console
vagrant box add --name 'centos/7/1804.02' CentOS-7-1804_02.box
```
Запущена ВМ при помощи Vagrantfile.

### 2. Уменьшение тома под / до 8G.

```console
sudo -i
```
Проверка дисков:
```console
lsblk
```
```
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
├─sda1                    8:1    0    1M  0 part
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk
sdc                       8:32   0    2G  0 disk
sdd                       8:48   0    1G  0 disk
sde                       8:64   0    1G  0 disk
```
Создание временного тома и перенос на него данных:
```console
pvcreate /dev/sdb
vgcreate vg_root /dev/sdb
lvcreate -n lv_root -l +100%FREE /dev/vg_root
mkfs.xfs /dev/vg_root/lv_root
mount /dev/vg_root/lv_root /mnt
xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
chroot /mnt/
grub2-mkconfig -o /boot/grub2/grub.cfg
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; > s/.img//g"` --force; done
```
Проверка результата:
```console
lsblk
```
```
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
├─sda1                    8:1    0    1M  0 part
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk
└─vg_root-lv_root       253:2    0   10G  0 lvm  /
sdc                       8:32   0    2G  0 disk
sdd                       8:48   0    1G  0 disk
sde                       8:64   0    1G  0 disk
```
В файле /boot/grub2/grub.cfg требуется заменить rd.lvm.lv=VolGroup00/LogVol00 на rd.lvm.lv=vg_root/lv_root для загрузки с нового (временного) тома при помощи:
```console
vi /boot/grub2/grub.cfg
```
Рестарт системы:
```console
sudo reboot
```
Удаление старого тома и его повторное создание с уменьшенном размером:
```console
lvremove /dev/VolGroup00/LogVol00
lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00
mkfs.xfs /dev/VolGroup00/LogVol00
```
Перенос данных на ново-созданный том:
```console
mount /dev/VolGroup00/LogVol00 /mnt
xfsdump -J - /dev/vg_root/lv_root | xfsrestore -J - /mnt
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
chroot /mnt/
grub2-mkconfig -o /boot/grub2/grub.cf
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; > s/.img//g"` --force; done
```

### 3. Выделение тома под /var в mirror.

Создание зеркала:
```console
pvcreate /dev/sd{c,d}
vgcreate vg_var /dev/sd{c,d}
lvcreate -L 950M -m1 -n lv_var vg_var
mkfs.ext4 /dev/vg_var/lv_var
```
Проверка результата:
```console
lsblk
```
```
NAME                     MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                        8:0    0   40G  0 disk
├─sda1                     8:1    0    1M  0 part
├─sda2                     8:2    0    1G  0 part /boot
└─sda3                     8:3    0   39G  0 part
  ├─VolGroup00-LogVol01  253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol00  253:2    0    8G  0 lvm
sdb                        8:16   0   10G  0 disk
└─vg_root-lv_root        253:0    0   10G  0 lvm
sdc                        8:32   0    2G  0 disk
├─vg_var-lv_var_rmeta_0  253:3    0    4M  0 lvm
│ └─vg_var-lv_var        253:7    0  952M  0 lvm
└─vg_var-lv_var_rimage_0 253:4    0  952M  0 lvm
  └─vg_var-lv_var        253:7    0  952M  0 lvm
sdd                        8:48   0    1G  0 disk
├─vg_var-lv_var_rmeta_1  253:5    0    4M  0 lvm
│ └─vg_var-lv_var        253:7    0  952M  0 lvm
└─vg_var-lv_var_rimage_1 253:6    0  952M  0 lvm
  └─vg_var-lv_var        253:7    0  952M  0 lvm
sde                        8:64   0    1G  0 disk
```
Перенос данных:
```console
mount /dev/vg_var/lv_var /mnt
cp -aR /var/* /mnt/
mkdir /tmp/oldvar && mv /var/* /tmp/oldvar
umount /mnt
mount /dev/vg_var/lv_var /var
echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab
```
Рестарт системы:
```console
sudo reboot
```
Удаление временного тома для /:
```
lvremove /dev/vg_root/lv_root
vgremove /dev/vg_root
pvremove /dev/sdb
```

### 4. Выделение тома под /home.

Создание, монтирование и перенос данных:
```console
lvcreate -n LogVol_Home -L 2G /dev/VolGroup00
mkfs.xfs /dev/VolGroup00/LogVol_Home
mount /dev/VolGroup00/LogVol_Home /mnt/
cp -aR /home/* /mnt/
rm -rf /home/*
umount /mnt
mount /dev/VolGroup00/LogVol_Home /home/
echo "`blkid | grep Home | awk '{print $2}'` /home xfs defaults 0 0" >> /etc/fstab
```
Проверка результата:
```console
lsblk
```
```
NAME                       MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                          8:0    0   40G  0 disk
├─sda1                       8:1    0    1M  0 part
├─sda2                       8:2    0    1G  0 part /boot
└─sda3                       8:3    0   39G  0 part
  ├─VolGroup00-LogVol00    253:0    0    8G  0 lvm  /
  ├─VolGroup00-LogVol01    253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol_Home 253:2    0    2G  0 lvm  /home
sdb                          8:16   0   10G  0 disk
sdc                          8:32   0    2G  0 disk
├─vg_var-lv_var_rmeta_0    253:3    0    4M  0 lvm
│ └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_0   253:4    0  952M  0 lvm
  └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
sdd                          8:48   0    1G  0 disk
├─vg_var-lv_var_rmeta_1    253:5    0    4M  0 lvm
│ └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_1   253:6    0  952M  0 lvm
  └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
sde                          8:64   0    1G  0 disk
```

### 5. Работа со снэпшотами:

Генерация файлов для работы со снэпшотами:

```console
touch /home/file{1..20}
```
Проверка результата:
```console
ls -al /home
```
```
total 0
drwxr-xr-x.  3 root    root    292 May  2 21:47 .
drwxr-xr-x. 18 root    root    239 May  2 21:25 ..
-rw-r--r--.  1 root    root      0 May  2 21:36 file1
-rw-r--r--.  1 root    root      0 May  2 21:36 file10
-rw-r--r--.  1 root    root      0 May  2 21:47 file11
-rw-r--r--.  1 root    root      0 May  2 21:47 file12
-rw-r--r--.  1 root    root      0 May  2 21:47 file13
-rw-r--r--.  1 root    root      0 May  2 21:47 file14
-rw-r--r--.  1 root    root      0 May  2 21:47 file15
-rw-r--r--.  1 root    root      0 May  2 21:47 file16
-rw-r--r--.  1 root    root      0 May  2 21:47 file17
-rw-r--r--.  1 root    root      0 May  2 21:47 file18
-rw-r--r--.  1 root    root      0 May  2 21:47 file19
-rw-r--r--.  1 root    root      0 May  2 21:36 file2
-rw-r--r--.  1 root    root      0 May  2 21:47 file20
-rw-r--r--.  1 root    root      0 May  2 21:36 file3
-rw-r--r--.  1 root    root      0 May  2 21:36 file4
-rw-r--r--.  1 root    root      0 May  2 21:36 file5
-rw-r--r--.  1 root    root      0 May  2 21:36 file6
-rw-r--r--.  1 root    root      0 May  2 21:36 file7
-rw-r--r--.  1 root    root      0 May  2 21:36 file8
-rw-r--r--.  1 root    root      0 May  2 21:36 file9
drwx------.  3 vagrant vagrant  95 May  2 21:09 vagrant
```
Создание тома для снэпшота:
```console
lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol_Home
```
Проверка результата:
```console
lsblk
```
```
NAME                            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                               8:0    0   40G  0 disk
├─sda1                            8:1    0    1M  0 part
├─sda2                            8:2    0    1G  0 part /boot
└─sda3                            8:3    0   39G  0 part
  ├─VolGroup00-LogVol00         253:0    0    8G  0 lvm  /
  ├─VolGroup00-LogVol01         253:1    0  1.5G  0 lvm  [SWAP]
  ├─VolGroup00-LogVol_Home-real 253:8    0    2G  0 lvm
  │ ├─VolGroup00-LogVol_Home    253:2    0    2G  0 lvm  /home
  │ └─VolGroup00-home_snap      253:10   0    2G  0 lvm
  └─VolGroup00-home_snap-cow    253:9    0  128M  0 lvm
    └─VolGroup00-home_snap      253:10   0    2G  0 lvm
sdb                               8:16   0   10G  0 disk
sdc                               8:32   0    2G  0 disk
├─vg_var-lv_var_rmeta_0         253:3    0    4M  0 lvm
│ └─vg_var-lv_var               253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_0        253:4    0  952M  0 lvm
  └─vg_var-lv_var               253:7    0  952M  0 lvm  /var
sdd                               8:48   0    1G  0 disk
├─vg_var-lv_var_rmeta_1         253:5    0    4M  0 lvm
│ └─vg_var-lv_var               253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_1        253:6    0  952M  0 lvm
  └─vg_var-lv_var               253:7    0  952M  0 lvm  /var
sde                               8:64   0    1G  0 disk
```
Удаление части файлов:
```console
rm -f /home/file{11..20}
```
Проверка результата:
```console
ls -al /home
```
```
total 0
drwxr-xr-x.  3 root    root    152 May  2 21:48 .
drwxr-xr-x. 18 root    root    239 May  2 21:25 ..
-rw-r--r--.  1 root    root      0 May  2 21:36 file1
-rw-r--r--.  1 root    root      0 May  2 21:36 file10
-rw-r--r--.  1 root    root      0 May  2 21:36 file2
-rw-r--r--.  1 root    root      0 May  2 21:36 file3
-rw-r--r--.  1 root    root      0 May  2 21:36 file4
-rw-r--r--.  1 root    root      0 May  2 21:36 file5
-rw-r--r--.  1 root    root      0 May  2 21:36 file6
-rw-r--r--.  1 root    root      0 May  2 21:36 file7
-rw-r--r--.  1 root    root      0 May  2 21:36 file8
-rw-r--r--.  1 root    root      0 May  2 21:36 file9
drwx------.  3 vagrant vagrant  95 May  2 21:09 vagrant
```
Восстановление данных:
```console
umount /home
lvconvert --merge /dev/VolGroup00/home_snap
mount /home
```
Проверка результата:
```console
ls -al /home
```
```
total 0
drwxr-xr-x.  3 root    root    292 May  2 21:47 .
drwxr-xr-x. 18 root    root    239 May  2 21:25 ..
-rw-r--r--.  1 root    root      0 May  2 21:36 file1
-rw-r--r--.  1 root    root      0 May  2 21:36 file10
-rw-r--r--.  1 root    root      0 May  2 21:47 file11
-rw-r--r--.  1 root    root      0 May  2 21:47 file12
-rw-r--r--.  1 root    root      0 May  2 21:47 file13
-rw-r--r--.  1 root    root      0 May  2 21:47 file14
-rw-r--r--.  1 root    root      0 May  2 21:47 file15
-rw-r--r--.  1 root    root      0 May  2 21:47 file16
-rw-r--r--.  1 root    root      0 May  2 21:47 file17
-rw-r--r--.  1 root    root      0 May  2 21:47 file18
-rw-r--r--.  1 root    root      0 May  2 21:47 file19
-rw-r--r--.  1 root    root      0 May  2 21:36 file2
-rw-r--r--.  1 root    root      0 May  2 21:47 file20
-rw-r--r--.  1 root    root      0 May  2 21:36 file3
-rw-r--r--.  1 root    root      0 May  2 21:36 file4
-rw-r--r--.  1 root    root      0 May  2 21:36 file5
-rw-r--r--.  1 root    root      0 May  2 21:36 file6
-rw-r--r--.  1 root    root      0 May  2 21:36 file7
-rw-r--r--.  1 root    root      0 May  2 21:36 file8
-rw-r--r--.  1 root    root      0 May  2 21:36 file9
drwx------.  3 vagrant vagrant  95 May  2 21:09 vagrant
```
После восстановления данных снэпшот удаляется:
```console
lsblk
```
```
NAME                       MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                          8:0    0   40G  0 disk
├─sda1                       8:1    0    1M  0 part
├─sda2                       8:2    0    1G  0 part /boot
└─sda3                       8:3    0   39G  0 part
  ├─VolGroup00-LogVol00    253:0    0    8G  0 lvm  /
  ├─VolGroup00-LogVol01    253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol_Home 253:2    0    2G  0 lvm  /home
sdb                          8:16   0   10G  0 disk
sdc                          8:32   0    2G  0 disk
├─vg_var-lv_var_rmeta_0    253:3    0    4M  0 lvm
│ └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_0   253:4    0  952M  0 lvm
  └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
sdd                          8:48   0    1G  0 disk
├─vg_var-lv_var_rmeta_1    253:5    0    4M  0 lvm
│ └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_1   253:6    0  952M  0 lvm
  └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
sde                          8:64   0    1G  0 disk
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
```
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
```

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