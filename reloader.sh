#!/bin/sh

set -e

MONITORING_HOST=${MONITORING_HOST:-"monitoring"}
MONITORING_PORT=${UPSOURCE_MONITORING_LISTEN_PORT:-"10080"}
HAPROXY_CONF_LOCATION=${HAPROXY_CONF_LOCATION:-"/usr/local/etc/haproxy"}
HAPROXY_SCRIPTS_LOCATION=${HAPROXY_SCRIPTS_LOCATION:-"/opt/upsource-haproxy"}

ONE_TIME=false
if [ ! -z "$1" ] && [ "$1" = "oneTime" ] ; then
    ONE_TIME=true
fi

while true ; do
  python2.7 ${HAPROXY_SCRIPTS_LOCATION}/loadbalancer.py http://${MONITORING_HOST}:${MONITORING_PORT}/monitoring/frontends /conf/haproxy/haproxy.cfg.tmpl ${HAPROXY_CONF_LOCATION}/haproxy.cfg /var/run/haproxy-systemd-wrapper.pid
  if [ "$ONE_TIME" = true ]; then
     break;
  fi
  sleep 2
done
