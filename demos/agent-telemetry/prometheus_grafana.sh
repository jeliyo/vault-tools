#!/usr/bin/env bash -x

prometheus --config.file=prometheus.yaml > /tmp/prometheus.log 2>&1 &

/usr/local/opt/grafana/bin/grafana-server --config grafana.yaml --homepath /usr/local/opt/grafana/share/grafana --packaging=brew cfg:default.paths.logs=/usr/local/var/log/grafana cfg:default.paths.data=/usr/local/var/lib/grafana cfg:default.paths.plugins=/usr/local/var/lib/grafana/plugins > /tmp/grafana.log 2>&1 &
