# Работа с загрузчиком

## Описание задачи

1. Попасть в систему без пароля несколькими способами.
2. Установить систему с LVM, после чего переименовать VG.
3. Добавить модуль в initrd.

## Выполнение

### 1. Попасть в систему без пароля несколькими способами.

Скачен образ с Ubuntu-22.04.
При помощи команды образ добавлен в Vagrant:
```console
vagrant box add --name 'ubuntu/22' Ubuntu-22.VirtualBox.box
```
Запущена ВМ при помощи Vagrantfile.

Включение отображения меню Grub:
```console
sudo -i
vi /etc/default/grub
```
```
#GRUB_TIMEOUT_STYLE=hidden
GRUB_TIMEOUT=10
```
Обновление конфигурации загрузчика:
```console
update-grub
```
Для alma и centos команда:
```console
grub2-mkconfig -o /boot/grub2/grub.cfg
```

#### 1.1 Первый способ.

После перезагрузки во время отображения меню загрузчика нужно нажать "e" для изменения параметров.
В конце строки "linux" добавлен "init=/bin/bash":

Для перемонтирования рутовой файловой системы в режим чтение-запись:
```console
mount -o remount,rw /
```

#### 1.2 Второй способ.

После перезагрузки во время отображения меню загрузчика нужно выюрать "Advanced options"
и загрузить систему в режиме восстановления (recovery mode).
При включенной поддержке сети (network) выбрать "root":

### 2. Установить систему с LVM, после чего переименовать VG.

Проверка текущего наименования VG:
```console
sudo -i
vgs
```
```
  VG        #PV #LV #SN Attr   VSize    VFree
  ubuntu-vg   1   1   0 wz--n- <126.00g 63.00g
```
Переименование и проверка результата:
```console
vgrename ubuntu-vg ubuntu-newname
vgs
```
```
  VG             #PV #LV #SN Attr   VSize    VFree
  ubuntu-newname   1   1   0 wz--n- <126.00g 63.00g
```
Проверка текущего наименования LV:
```console
lvs
```
```
  LV        VG             Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  ubuntu-lv ubuntu-newname -wi-ao---- <63.00g
```
Переименование и проверка результата:
```console
lvrename ubuntu-newname ubuntu-lv ubuntu-newnamelv
lvs
```
```
  LV               VG             Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  ubuntu-newnamelv ubuntu-newname -wi-ao---- <63.00g
```

### 3. Добавить модуль в initrd.
Для успешной загрузки с LV с новым наименованием нужно изменить /boot/grub/grub.cfg:
