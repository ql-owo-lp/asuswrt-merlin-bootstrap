#!/bin/sh

# paste the following command to /jffs/script/firewall-start
# wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/kevinxw/asuswrt-merlin-bootstrap/master/dnsmasq/adblock-hosts-generator-bootstrap.sh' | sh &

cd /tmp
wget --no-check-certificate -q 'https://github.com/kevinxw/asuswrt-merlin-bootstrap/raw/master/dnsmasq/generated-files/hosts.dnsmasq.gz'
gunzip -f ./hosts.dnsmasq.gz

service restart_dnsmasq
