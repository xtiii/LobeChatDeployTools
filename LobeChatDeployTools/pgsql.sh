#!/bin/bash

### BEGIN INIT INFO
# Provides:          pgsql
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts Pgsql
# Description:       PostgreSQL Database Server
### END INIT INFO
# PostgreSQL控制脚本
case $1 in
start)
  su - postgres -c 'postgres -D $PGDATA >>$PGHOME/logs/pgsql.log 2>&1 &'
  su - postgres -c 'echo 已启动，详细请看日志：$PGHOME/logs/pgsql.log'
  ;;
stop)
  su - postgres -c 'kill -INT $(head -1 $PGDATA/postmaster.pid)'
  ;;
restart)
  su - postgres -c 'pg_ctl -D $PGDATA >>$PGHOME/logs/pgsql.log stop 2>&1 &'
  sleep 1
  su - postgres -c 'postgres -D $PGDATA >>$PGHOME/logs/pgsql.log 2>&1 &'
  su - postgres -c 'echo 已重启，详细请看日志：$PGHOME/logs/pgsql.log'
  ;;
reload)
  su - postgres -c 'pg_ctl -D $PGDATA >>$PGHOME/logs/pgsql.log reload 2>&1 &'
  su - postgres -c 'echo 已重载，详细请看日志：$PGHOME/logs/pgsql.log'
  ;;
*)
  echo 'usage start|stop|restart|reload'
  exit 1
  ;;
esac
