ДЗ #1

1. Сконфигурирован файл docker-compose.yml.
2. Создан файл .env для использования переменных в docker-compose.
3. Сконфигурирован файл prometheus.yml для сбора метрик с экспортеров.
4. Сконфигурирован фалй web.yml для использования basic auth.
5. Сконфигурирован файл www.conf для доступа к статусу php-fpm.
6. Сконфигурирован файл nginx.conf для web-страниц worpress, nginx_status, fpm_status (последние две для сбора метрик).
7. Сконфигурирован файл config.yml для blackbox exporter.

------------------------------------------------------------------------------------------------------------------------
Для первого запуска в docker-compose.yml нужно раскомментировать строки с командой для Mysql.
Команда выполняет первоначальние настройки mysql.
После успешного старта на контейнере с Mysql требуется выполнить команды:
CREATE USER 'user_for_exporter_db'@'%' IDENTIFIED BY 'pass_for_exporter_db';
GRANT PROCESS, REPLICATION CLIENT ON *.* TO 'user_for_exporter_db'@'%';
GRANT SELECT ON performance_schema.* TO 'user_for_exporter_db'@'%';
GRANT SELECT, RELOAD, SUPER, LOCK TABLES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'user_for_exporter_db'@'%';
Эти команды создадут юзера для сбора метрик с mysql.
Затем строки с командой нужно закомментировать и перезапусть контейнер с Mysql.

Дополнительно для мониторинга windows-хоста (на котором установлен докер с проектом), установлен и запущен wmi_exporter.

В Grafana экспортируются дашборды для визуализации данных.
------------------------------------------------------------------------------------------------------------------------

ДЗ #2

1. В файл docker-compose.yml добавлен контейнер alertmanager.
2. Создан alert.rules.yml для настройки условий алертов.
3. Создан alertmanager.yml для настройки отправки уведомлений в два канала telagram.
4. Скорректирован prometheus.yml для использования alertmanager и alert.rules.yml.
5. В grafana добавлен источник данных alertmanager и дашборд для визуализации работы alertmanager.

В папке examples скриншоты пришедших алертов.