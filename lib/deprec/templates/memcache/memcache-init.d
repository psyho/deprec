#!/bin/sh

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/local/bin/memcached
DAEMONBOOTSTRAP=/usr/local/share/memcached/scripts/start-memcached
NAME=memcached
DESC=memcached
PIDFILE=/var/run/$NAME.pid

test -x $DAEMON || exit 0
test -x $DAEMONBOOTSTRAP || exit 0

set -e

case "$1" in
    start)
        echo -n "Starting $DESC: "
        start-stop-daemon --start --quiet --exec $DAEMONBOOTSTRAP -- -d -m <%= memcache_memory %> -l <%= memcache_ip %> -p <%= memcache_port %> -f <%= memcache_factor %> -s <%= memcache_minsize %> -c <%= memcache_conn %>
        echo "$NAME."
        ;;
    stop)
        echo -n "Stopping $DESC: "
        start-stop-daemon --stop --quiet --oknodo --pidfile $PIDFILE --exec $DAEMON
        echo "$NAME."
        rm -f $PIDFILE
        ;;

    restart|force-reload)
        echo -n "Restarting $DESC: "
        start-stop-daemon --stop --quiet --oknodo --pidfile $PIDFILE
        rm -f $PIDFILE
        sleep 1
        start-stop-daemon --start --quiet --exec $DAEMONBOOTSTRAP
        echo "$NAME."
        ;;
    *)
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop|restart|force-reload}" >&2
        exit 1
        ;;
esac

exit 0