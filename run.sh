#!/bin/bash

set -e

MONITORING_HOST=${MONITORING_HOST:-"monitoring"}
MONITORING_PORT=${UPSOURCE_MONITORING_LISTEN_PORT:-"10080"}
HAPROXY_CONF_LOCATION=${HAPROXY_CONF_LOCATION:-"/usr/local/etc/haproxy"}
HAPROXY_SCRIPTS_LOCATION=${HAPROXY_SCRIPTS_LOCATION:-"/opt/upsource-haproxy"}

# Init haproxy config
python -c 'import loadbalancer; loadbalancer.init_config()' http://${MONITORING_HOST}:${MONITORING_PORT}/monitoring/frontends ${HAPROXY_SCRIPTS_LOCATION}/conf/haproxy/haproxy.cfg.tmpl ${HAPROXY_CONF_LOCATION}/haproxy.cfg

# haproxy-systemd-wrapper is a built-in haproxy wrapper
"$(which haproxy-systemd-wrapper)" -p /var/run/haproxy.pid -f ${HAPROXY_CONF_LOCATION}/haproxy.cfg "$@" & echo $! > /var/run/haproxy-systemd-wrapper.pid
#haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg

#/reloader.sh oneTime
# schedule reloading of configs
${HAPROXY_SCRIPTS_LOCATION}/reloader.sh &

wait
