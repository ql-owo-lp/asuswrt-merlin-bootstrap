#!/bin/sh

cd /tmp
wget --no-check-certificate -q 'https://github.com/kevinxw/asuswrt-merlin-bootstrap/raw/master/dnsmasq/generated-files/hosts.dnsmasq.gz'
gunzip -f ./hosts.dnsmasq.gz

service restart_dnsmasq
