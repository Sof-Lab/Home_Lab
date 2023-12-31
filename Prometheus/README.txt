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
------------------------------------------------------------------------------------------------------------------------
ДЗ #3

1. В docker-compose.yml добавлен контейнер victoria (victoria metrics).
2. В файл prometheus.yml добавлены настройки external_lables, remote_write, добавлен таргет victoria.
3. В grafana добавлен источник victoria, добавлен дашборд для таргета victoria, добавлены дашборды для экспортеров с источником victoria для проверки.
------------------------------------------------------------------------------------------------------------------------
ДЗ #4 Grafana

1. В Grafana созданы папки с названиями infra и app.
2. В папке infra создан дашборд с названием infra.
3. На дашборде infra при нажатии на панель Hard Disk Usage в новом окне открывается дашборд node-exporter disk graphs, который импортирован из библиотеки дашбордов grafana.
4. В папке app создан дашборд CMS.
5. На дашборде CMS при нажатии на панель MysSQL Status в новом окне открывается дашборд node-exporter mysql overview, который импортирован из библиотеки дашбордов grafana.
6. Добавлен Contact point - Telegram для отправки уведомлений в чат телеграм через бота.
7. Добавлен Notification policу с правилом, что канал отправки уведомлений по умолчанию - созданный канал телеграм.
8. Создан алерт на отсутствие данных по метрике по nginx_up.
9. Создан алерт на probe_success=0 (неудачное выполнение blackbox probe).
10. После тестов уведомления получены успешно.
11. Скриншоты дашбордов и полученных уведомлений в папке "screenshots".