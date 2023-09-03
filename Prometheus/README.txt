1. Сконфигурирован файл docker-compose.yml.
2. Создан файл .env для использования переменных в docker-compose.
3. Сконфигурирован файл prometheus.yml для сбора метрик с экспортеров.
4. Сконфигурирован фалй web.yml для использования basic auth.
5. Сконфигурирован файл www.conf для доступа к статусу php-fpm.
6. Сконфигурирован файл nginx.conf для web-страниц worpredd, nginx_status, fpm_status (последние две для сбора метрик).
7. Сконфигурирован файл config.yml для blackbox exporter.

------------------------------------------------------------------------------------------------------------------------
Для первого запуска в docker-compose.yml нужно раскомментировать строки с командой для Mysql.
Команда выполняет первоначальние настройки mysql.
После успешного старта на контейнере с Mysql требуется выполнить команды:
CREATE USER 'exporter'@'%' IDENTIFIED BY 'exporter';
GRANT PROCESS, REPLICATION CLIENT ON *.* TO 'exporter'@'%';
GRANT SELECT ON performance_schema.* TO 'exporter'@'%';
GRANT SELECT, RELOAD, SUPER, LOCK TABLES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'exporter'@'%';
Эти команды создадут юзера для сбора метрик с mysql.
Затем строки с командой нужно закомментировать и перезапусть контейнер с Mysql.

В Grafana экспортируются дашборды для визуализации данных.