ДЗ #6

1. Сконфигурирован файл docker-compose.yml.
2. Сконфигурированы файлы kibana.yml и logstash.yml для связности с elasticsearch.
3. Создан файл 01-json-temlate.conf для преобразования логов в json.
4. Сконфигурированы файлы rsyslog.conf и 60-output.conf для отправки логов по аутентификации в logstash.
5. Сконфигурирован файл logstash.conf для приёма, обаработки и отправки логов в elasticsearch.
6. Скорректированы поля для отоборажения Stream-логов в Kibana.
7. Создан dashboard в kibana, который отображает количество успешных и неуспешных подключений по ssh.

Конфигурационные файлы rsyslog и logstash лежат в папке Configs.
Скриншоты kibana и проверка index в elasticsearch находятся в папке Screenshoats.
