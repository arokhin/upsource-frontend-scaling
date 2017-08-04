#!/bin/sh

set -e

MONITORING_HOST=${MONITORING_HOST:-"monitoring"}
MONITORING_PORT=${UPSOURCE_MONITORING_LISTEN_PORT:-"10080"}

ONE_TIME=false
if [ ! -z "$1" ] && [ "$1" = "oneTime" ] ; then
    ONE_TIME=true
fi

while true ; do
  python2.7 /loadbalancer.py http://${MONITORING_HOST}:${MONITORING_PORT}/monitoring/frontends /conf/haproxy/haproxy.cfg.tmpl /usr/local/etc/haproxy/haproxy.cfg /var/run/haproxy-systemd-wrapper.pid
  if [ "$ONE_TIME" = true ]; then
     break;
  fi
  sleep 2
done
