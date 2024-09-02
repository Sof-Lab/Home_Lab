# Управление процессами

## Описание задачи

1. Написать свою реализацию ps ax используя анализ /proc;
2. Написать свою реализацию lsof;
3. Дописать обработчики сигналов в прилагаемом скрипте, оттестировать, приложить сам скрипт, инструкции по использованию;
4. Реализовать 2 конкурирующих процесса по IO. пробовать запустить с разными ionice;
5. Реализовать 2 конкурирующих процесса по CPU. пробовать запустить с разными nice.

## Выполнение

### 1. Написать свою реализацию ps ax используя анализ /proc.

Скрипт на bash [ps_ax.sh](https://github.com/Sof-Lab/Home_Lab/blob/main/Linux/Proc/ps_ax.sh) выводит некоторую информации по аналогии утилиты `ps ax`.

### 2. Написать свою реализацию lsof.

Скрипт на bash [lsof.sh](https://github.com/Sof-Lab/Home_Lab/blob/main/Linux/Proc/lsof.sh) выводит некоторую информации по аналогии утилиты `lsof`.

### 3. Дописать обработчики сигналов в прилагаемом скрипте.

Скрипт [myfork.py](https://github.com/Sof-Lab/Home_Lab/blob/main/Linux/Proc/myfork.py) содержит некоторую обработку сигналов.
Нажатие Ctrl+c при запущенном скрипте выдает:
```
[root@proc ~]# python3 myfork.py
Hello! I am an example
pid of my child is 32798
HHHrrrrr
pid of my child is 0
I am a child. Im going to sleep
mrrrrr
2
my child pid is 32799
my name is 2
^CI am dying...
I am dying...
[root@proc ~]#
```
Если выполнить `kill` для родительских процессов, получаем:
```
[root@proc ~]# python3 myfork.py
Hello! I am an example
pid of my child is 32818
HHHrrrrr
pid of my child is 0
I am a child. Im going to sleep
mrrrrr
2
my child pid is 32819
my name is 2
3
HHHrrrrr
mrrrrr
4
my child pid is 32820
my name is 4
9
HHHrrrrr
mrrrrr
8
my child pid is 32821
my name is 8
27
HHHrrrrr
mrrrrr
16
my child pid is 32822
my name is 16
81
HHHrrrrr
mrrrrr
32
my child pid is 32823
my name is 32
I am dying...
243
HHHrrrrr
729
HHHrrrrr
2187
HHHrrrrr
6561
HHHrrrrr
19683
HHHrrrrr
59049
HHHrrrrr
177147
HHHrrrrr
I am dying...
[root@proc ~]#
```

### 4. Реализовать 2 конкурирующих процесса по IO. пробовать запустить с разными ionice.

Скрипт на bash [io.sh](https://github.com/Sof-Lab/Home_Lab/blob/main/Linux/Proc/io.sh) использовался для запуска процессов с разным ionice.
Результат для первой раскомментированной строки в скрипте:
```
[root@proc ~]# ./io.sh

real    0m18.216s
user    0m0.005s
sys     0m0.630s

real    0m19.034s
user    0m0.003s
sys     0m0.697s
```
Для второй:
```
[root@proc ~]# ./io.sh

real    0m19.015s
user    0m0.008s
sys     0m0.638s

real    0m19.125s
user    0m0.003s
sys     0m0.699s
```
Для третьей:
```
[root@proc ~]# ./io.sh

real    0m18.914s
user    0m0.000s
sys     0m0.670s

real    0m19.644s
user    0m0.006s
sys     0m0.698s
```
Для четвертой:
```
[root@proc ~]# ./io.sh

real    0m19.000s
user    0m0.014s
sys     0m0.640s

real    0m19.342s
user    0m0.004s
sys     0m0.660s
```

### 5. Реализовать 2 конкурирующих процесса по CPU. пробовать запустить с разными nice.

Скрипт на bash [cpu.sh](https://github.com/Sof-Lab/Home_Lab/blob/main/Linux/Proc/cpu.sh) использовался для запуска процессов с разным nice.
Результат для первой раскомментированной строки в скрипте:
```
[root@proc ~]# ./cpu.sh

real    0m7.091s
user    0m0.026s
sys     0m0.221s

real    0m7.501s
user    0m0.023s
sys     0m0.241s
```
Для второй:
```
[root@proc ~]# ./cpu.sh

real    0m4.534s
user    0m0.047s
sys     0m0.203s

real    0m8.249s
user    0m0.034s
sys     0m0.246s
```