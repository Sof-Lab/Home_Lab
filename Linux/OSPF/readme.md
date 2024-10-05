# Vagrant-Ansible стeнд для работы с OSPF

## Описание задачи

Поднять три виртуалки.
Объединить их разными vlan
- поднять OSPF между машинами на базе Quagga;
- изобразить асимметричный роутинг;
- сделать один из линков "дорогим", но что бы при этом роутинг был симметричным.

## Выполнение

*Лабораторный стенд развёрнут на хосте с Windows + WSL2. На Windows установлены Vagrant и VirtualBox. Ansible установлен на WSL.*

*Все файлы для vagrant располагаются в директории windows (win_directory), у меня это - D:\VBox_Projects\ospf\. Команды для работы с vagrant запускаются из той же директории.*

*Все файлы для ansible располагаются в директории wsl (wsl_directory), у меня это - /home/sof/sof/otus_labs/ospf/. Команды для работы с ansible звпускаются из той же директории.*

### 1. Разворачивание стенда при помощи Vagrant.

Создан Vagrantfile *(win_directory)* для разворачивания лабороторного стенда.

Для доступа к вм из wsl в Vagrantfile прописан дополнительный проброс порта `ssh-for-wsl` для каждой вм.
В нём нужно указать ip-адрес хоста и желаемый порт ssh для подключения:
```
:wsl =>	[{auto_correct: true, guest: 22, host: 'указать порт для подключения по ssh', host_ip: "указать ip-адреса Windows хоста", id: "ssh-for-wsl"}],
```

### 2. Настройка стенда при помощи Ansible.

В файле staging/hosts.yaml *(wsl_directory)* нужно заполнить переменные для выполнения настройки стенда.
Для подключения к ВМ:
```
    host_ip: 192.168.1.8 # windows host ip
    dir_wsl: /home/sof/otus_labs/ospf/ # directory wsl whith ansible files
    dir_vagrant: /mnt/d/VBox_Projects/ospf/ # directory wsl whith vagrant files
	
	ansible_port: 'указать порт для подключения по ssh' # указывается к каждой вм согласно настройкам в Vagrantfile ":wsl"
```
Также в staging/hosts.yaml *(wsl_directory)* добавлены переменные для заполнения конфигурационного файла `frr.conf`:
```
    router_id_enable: false # заменить на true, чтобы в frr.conf вносилась соответствующая запись
    symmetric_routing: false # заменить на true, чтобы настроить симментиричный роутинг

# Заполняется для каждого роутера в стенде:

            router_id: 
            neighbor1: 
            neighbor2: 
            enp0s8:
              description: 
            enp0s9:
              description: 
            enp0s10:
              description: 
```
В файле staging/hosts.yaml *(wsl_directory)* дополнительно прописан localhost для выполнения команд в wsl.
Это требуется, чтобы скопировать ключ private_key для подключения к ВМ из директории windows в директорию wsl.

PLAY `WSL localhost copy private_key` копирует private_key на wsl.

### 3. Проверка результатов.

Проверка доступности сетей:
```
root@router1:~$ ping 192.168.30.1
PING 192.168.30.1 (192.168.30.1) 56(84) bytes of data.
64 bytes from 192.168.30.1: icmp_seq=1 ttl=64 time=0.680 ms
64 bytes from 192.168.30.1: icmp_seq=2 ttl=64 time=2.45 ms

root@router1:~$ traceroute 192.168.30.1
traceroute to 192.168.30.1 (192.168.30.1), 30 hops max, 60 byte packets
 1  192.168.30.1 (192.168.30.1)  0.436 ms  0.377 ms  0.665 ms
```
Проверка динамического роутинга. Отключение интерфейса:
```
root@router1:~# ifconfig enp0s9 down
```
В результате маршрут изменился, сеть по-прежнему доступна:
```
root@router1:~# traceroute 192.168.30.1
traceroute to 192.168.30.1 (192.168.30.1), 30 hops max, 60 byte packets
 1  10.0.10.2 (10.0.10.2)  0.708 ms  0.635 ms  0.586 ms
 2  192.168.30.1 (192.168.30.1)  2.000 ms  1.953 ms  1.908 ms
 
root@router1:~# vtysh
router1# show ip route ospf
O   10.0.10.0/30 [110/1000] is directly connected, enp0s8, weight 1, 00:00:39
O>* 10.0.11.0/30 [110/1100] via 10.0.10.2, enp0s8, weight 1, 00:00:39
O>* 10.0.12.0/30 [110/1200] via 10.0.10.2, enp0s8, weight 1, 00:00:39
O   192.168.10.0/24 [110/100] is directly connected, enp0s10, weight 1, 00:19:43
O>* 192.168.20.0/24 [110/1100] via 10.0.10.2, enp0s8, weight 1, 00:00:39
O>* 192.168.30.0/24 [110/1200] via 10.0.10.2, enp0s8, weight 1, 00:00:39
```
Включение интерфейса после тестирования:
```
root@router1:~# ifconfig enp0s9 up

root@router1:~# vtysh
router1# show ip route ospf
O   10.0.10.0/30 [110/300] via 10.0.12.2, enp0s9, weight 1, 00:01:01
O>* 10.0.11.0/30 [110/200] via 10.0.12.2, enp0s9, weight 1, 00:01:01
O   10.0.12.0/30 [110/100] is directly connected, enp0s9, weight 1, 00:01:01
O   192.168.10.0/24 [110/100] is directly connected, enp0s10, weight 1, 00:21:02
O>* 192.168.20.0/24 [110/300] via 10.0.12.2, enp0s9, weight 1, 00:01:01
O>* 192.168.30.0/24 [110/200] via 10.0.12.2, enp0s9, weight 1, 00:01:01
```
Проверка асимметричного роутинга. Маршруты на router2:
```
root@router2:~# vtysh
router2# show ip route ospf
O   10.0.10.0/30 [110/100] is directly connected, enp0s8, weight 1, 00:21:26
O   10.0.11.0/30 [110/100] is directly connected, enp0s9, weight 1, 00:21:26
O>* 10.0.12.0/30 [110/200] via 10.0.10.1, enp0s8, weight 1, 00:01:20
  *                        via 10.0.11.1, enp0s9, weight 1, 00:01:20
O>* 192.168.10.0/24 [110/200] via 10.0.10.1, enp0s8, weight 1, 00:20:51
O   192.168.20.0/24 [110/100] is directly connected, enp0s10, weight 1, 00:21:26
O>* 192.168.30.0/24 [110/200] via 10.0.11.1, enp0s9, weight 1, 00:20:46
```
Запуск пинга на router1:
```
root@router1:~# ping -I 192.168.10.1 192.168.20.1
PING 192.168.20.1 (192.168.20.1) from 192.168.10.1 : 56(84) bytes of data.
64 bytes from 192.168.20.1: icmp_seq=1 ttl=64 time=1.02 ms
64 bytes from 192.168.20.1: icmp_seq=2 ttl=64 time=1.71 ms
64 bytes from 192.168.20.1: icmp_seq=3 ttl=64 time=1.03 ms
64 bytes from 192.168.20.1: icmp_seq=4 ttl=64 time=2.39 ms
...
```
Проверка трафика на разных портах router2:
```
root@router2:~# tcpdump -i enp0s9
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on enp0s9, link-type EN10MB (Ethernet), capture size 262144 bytes
16:26:15.588931 IP 192.168.10.1 > 192.168.20.1: ICMP echo request, id 2, seq 7, length 64
16:26:16.591137 IP 192.168.10.1 > 192.168.20.1: ICMP echo request, id 2, seq 8, length 64
16:26:17.594476 IP 192.168.10.1 > 192.168.20.1: ICMP echo request, id 2, seq 9, length 64
16:26:18.615033 IP 192.168.10.1 > 192.168.20.1: ICMP echo request, id 2, seq 10, length 64

root@router2:~# tcpdump -i enp0s8
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on enp0s8, link-type EN10MB (Ethernet), capture size 262144 bytes
16:26:38.672064 IP 192.168.20.1 > 192.168.10.1: ICMP echo reply, id 2, seq 30, length 64
16:26:39.675452 IP 192.168.20.1 > 192.168.10.1: ICMP echo reply, id 2, seq 31, length 64
16:26:40.677776 IP 192.168.20.1 > 192.168.10.1: ICMP echo reply, id 2, seq 32, length 64
16:26:41.683929 IP 192.168.20.1 > 192.168.10.1: ICMP echo reply, id 2, seq 33, length 64
16:26:42.686408 IP 192.168.20.1 > 192.168.10.1: ICMP echo reply, id 2, seq 34, length 64

```
Асимметричный роутинг работает: на одном интерфейсе пакеты только отправляются, на другом - поступают.

Настройка симметричного роутинга осуществляется путем изменения переменной в staging/hosts.yaml *(wsl_directory)*:
`symmetric_routing: false` --> `symmetric_routing: true`.
Затем запуск playbook `ansible-playbook ospf.yml -t setup_ospf`.
Снова запуск пинга на router1:
```
root@router1:~# ping -I 192.168.10.1 192.168.20.1
PING 192.168.20.1 (192.168.20.1) from 192.168.10.1 : 56(84) bytes of data.
64 bytes from 192.168.20.1: icmp_seq=1 ttl=63 time=1.50 ms
64 bytes from 192.168.20.1: icmp_seq=2 ttl=63 time=2.70 ms
```
Просмотр трафика на router2:
```
root@router2:~# tcpdump -i enp0s9
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on enp0s9, link-type EN10MB (Ethernet), capture size 262144 bytes
16:33:21.019086 IP 192.168.10.1 > 192.168.20.1: ICMP echo request, id 5, seq 7, length 64
16:33:21.019154 IP 192.168.20.1 > 192.168.10.1: ICMP echo reply, id 5, seq 7, length 64
16:33:22.021467 IP 192.168.10.1 > 192.168.20.1: ICMP echo request, id 5, seq 8, length 64
16:33:22.021540 IP 192.168.20.1 > 192.168.10.1: ICMP echo reply, id 5, seq 8, length 64
16:33:23.024209 IP 192.168.10.1 > 192.168.20.1: ICMP echo request, id 5, seq 9, length 64
16:33:23.024275 IP 192.168.20.1 > 192.168.10.1: ICMP echo reply, id 5, seq 9, length 64
```
Трафик в обе стороны идет через один интерфейс.