#!/bin/bash

set -e

MONITORING_HOST=${MONITORING_HOST:-"monitoring"}
MONITORING_PORT=${MONITORING_PORT:-"10080"}

# Init haproxy config
python -c 'import loadbalancer; loadbalancer.init_config()' http://${MONITORING_HOST}:${MONITORING_PORT}/monitoring/frontends /conf/haproxy/haproxy.cfg.tmpl /usr/local/etc/haproxy/haproxy.cfg

# haproxy-systemd-wrapper is a built-in haproxy wrapper
"$(which haproxy-systemd-wrapper)" -p /var/run/haproxy.pid -f /usr/local/etc/haproxy/haproxy.cfg "$@" & echo $! > /var/run/haproxy-systemd-wrapper.pid
#haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg

#/reloader.sh oneTime
# schedule reloading of configs
/reloader.sh &

wait
