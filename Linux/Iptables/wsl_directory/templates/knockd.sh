#!/bin/bash

# ip адрес хоста, к которому подключаемся
IP_ADDRESS="192.168.255.1"

# Порты, заданные в конфигурации knockd
KNOCK_PORTS=(7000 8000 9000)

# Отправка ударов
for PORT in "${KNOCK_PORTS[@]}"; do
    echo "Knocking on port $PORT..."
    nc -z -w 1 $IP_ADDRESS $PORT
done

# Теперь можно подключиться к SSH
echo "Port knocking complete, trying to connect via SSH..."
ssh $IP_ADDRESS
