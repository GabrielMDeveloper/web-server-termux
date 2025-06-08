#!/bin/bash

logs_dir="$HOME/.server/.logs"
server_start() {
    mkdir -p "$logs_dir"
    mariadbd-safe --datadir='/data/data/com.termux/files/usr/var/lib/mysql' > "$logs_dir" 2>&1 &
}

server_stop() {
    pkill mariadbd
    sleep 1
}

case "$1" in

start)
    server_start
    echo "MariaDB Iniciado"
    ;;
stop)
    server_stop
    echo -e "MariaDB Finalizado"
    ;;
restart)
    server_stop
    sleep 2
    server_start
    echo -e"\MariaDB reiniciado.\n"
    ;;
help)
    echo -e "Este comando inicia, para e reinicia o MariaDB\n Uso: $0 {start|stop|restart|help}"
    ;;
*)
    echo "Uso: $0 {start|stop|restart|help}"
    exit 1
    ;;
esac