# Vagrant-Ansible стeнд для развертывания веб приложения.

## Описание задачи

Развернуть динамический веб,
вариант стенда: nginx + php-fpm(wordpress) + python (django) + js(node.js) с деплоем через docker-compose.


## Выполнение

*Лабораторный стенд развёрнут на хосте с Windows + WSL2. На Windows установлены Vagrant и VirtualBox. Ansible установлен на WSL.*

*Все файлы для vagrant располагаются в директории windows (win_directory), у меня это - D:\VBox_Projects\web\. Команды для работы с vagrant запускаются из той же директории.*

*Все файлы для ansible располагаются в директории wsl (wsl_directory), у меня это - /home/sof/sof/otus_labs/web/. Команды для работы с ansible звпускаются из той же директории.*

### 1. Разворачивание стенда при помощи Vagrant.

Создан Vagrantfile *(win_directory)* для разворачивания лабороторного стенда.

Для доступа к вм из wsl в Vagrantfile прописан дополнительный проброс порта `ssh-for-wsl`.
В нём нужно указать ip-адрес хоста и желаемый порт ssh для подключения:

```
web.vm.network "forwarded_port", # дополнительный проброс порта для доступа к ВМ из WSL
			auto_correct: true,
			guest: 22,
			host: 'указать порт для подключения к вм по ssh'
			host_ip: 'указать ip адрес windows хоста'
			id: "ssh-for-wsl"
```
Дополнительно указан проброс портов для доступа через localhost к сайтам, которые будут доступны по разным портам:
```
    web.vm.network "forwarded_port", guest: 8081, host: 8081
    web.vm.network "forwarded_port", guest: 8082, host: 8082
	web.vm.network "forwarded_port", guest: 8083, host: 8083
```

### 2. Настройка стенда при помощи Ansible.

В файле staging/hosts.yaml *(wsl_directory)* нужно заполнить переменные для выполнения настройки стенда.
Для подключения к ВМ:
```
    host_ip: 'указать ip адрес windows хоста'
    dir_wsl: 'указать рабочую директорию для ansible в wsl'
    dir_vagrant: 'указать рабочую директорию для vagrant в wsl'
	
	ansible_port: 'указать порт для подключения к вм по ssh'
```
В файле staging/hosts.yaml *(wsl_directory)* дополнительно прописан localhost для выполнения команд в wsl.
Это требуется, чтобы скопировать ключ private_key для подключения к ВМ из директории windows в директорию wsl.

PLAY `WSL localhost copy private_key` в `web.yml` *(wsl_directory)* копирует private_key на wsl.
PLAY `Configure Dynamic Web` в `web.yml` *(wsl_directory)* производит необходимые настройки.
Перед запуском необходимо подготовить файлы в  project/ *(wsl_directory)*.

### 3. Настройка стенда при помощи Docker-compose.

В файле project/.env *(wsl_directory)* указаны значения переменных,
которые будут использованы при развертывании приложений через docker-compose:
```
# DB-WP Maria Set
export MARIA_ROOT_PASS='указать пароль для рута базы'

# Wordpress Set
export WP_DB_NAME='указать имя БД для wordpress'
export WP_DB_USER='указать имя пользователя в БД для wordpress'
export WP_DB_PASS='указать пароль пользователя в БД для wordpress'

# App python Set
export MYSITE_SECRET_KEY='указать secret_key'
```
В файле project/docker-compose.yml *(wsl_directory)* перечислены контейнеры и соответствующие настройки для них.
Контейнер `mariadb` используется в качестве БД для `wordpress`.
Проброс порта `expose:- "3306"` указан для открытия порта 3306 между контейнерами.
Оба контейнера реализуют первый сайт на базе php-fpm, который будет доступен по порту 8083
(настраивается в конфиг файле project/nginx-conf/wp.conf *(wsl_directory)* для nginx).
Контейнер `node` реализует сайт на базе js, используется скрипт project/node/test.js *(wsl_directory)*.
Сайт будет доступен по порту 8082
(настраивается в конфиг файле project/nginx-conf/node.conf *(wsl_directory)* для nginx).
Контейнер `app` реулизует сайт на базе python, используются файлы из project/python/*(wsl_directory)*.
Сайт будет доступен по порту 8081
(настраивается в конфиг файле project/nginx-conf/django.conf *(wsl_directory)* для nginx).
Контейнер `nginx` перенаправляет запросы по портам 8081-8083 к соответствующим контейнерам.

### 4. Проверка результатов.

В результате с хостовой машины попадаем на сайты по соответствующим портам:

![Image alt](https://github.com/Sof-Lab/Home_Lab/blob/main/Linux/Web/results/wordpress.png)

![Image alt](https://github.com/Sof-Lab/Home_Lab/blob/main/Linux/Web/results/js.png)

![Image alt](https://github.com/Sof-Lab/Home_Lab/blob/main/Linux/Web/results/django.png)