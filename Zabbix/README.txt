ДЗ #5 Zabbix

1. Сконфигурирован файл docker-compose.yml.
2. Создан файл .env для использования переменных в docker-compose.
3. Создан файл discovery.sh со скриптом, который отдает перечень созданных метрик (в папке zabbix).
4. Создан файл script.sh со скриптом, который отдает значение созданных метрик (в папке zabbix).
5. Изменен файл zabbix_agent.conf: добавлены UserParametr, которые обращаются к созданным скриптам:
UserParameter=otus_metrics.discovery,bash /usr/local/discovery.sh
UserParameter=otus_metrics.[*],bash /usr/local/script.sh $1
6. Создано правило обнаружения с ключом otus_metrics.discovery.
7. В правиле обнаружения создан прототип элемента данных с ключом otus_metrics.[{#METRIC}].
8. В правиле обнаружения создан прототип триггера с условием last(otus_metrics.[{#METRIC}])>=95
9. Создано правило отправки уведомлений по событиям в телеграм.
10. Получены уведомления по событиям.
11. В папку screenshots вложены скриншоты графика полученных метрик и получченных уведомлений.