#!/usr/bin/env bash

pkill prometheus

pkill grafana-server

pkill vault

docker kill postgres
