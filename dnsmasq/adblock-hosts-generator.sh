#!/bin/bash
# This if for Asuswrt-merlin

# 1. Add the following configs to /jffs/configs/dnsmasq.conf.add
#
# addn-hosts=/tmp/hosts.dnsmasq
#
# 2. Create the file /jffs/scripts/init-start with the following content:
# #!/bin/sh
# touch/tmp/hosts.dnsmasq
#
# 3. Grant exec permission: chmod a+x /jffs/scripts/*
#
# 4. Add the following line to /jffs/scripts/firewall-start :
# nice wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/kevinxw/asuswrt-merlin-bootstrap/master/dnsmasq-adblock.sh' | nice bash


declare -a DOMAIN_BLACKLIST=(
'https://pgl.yoyo.org/as/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext'
'https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts'
'http://mirror1.malwaredomains.com/files/justdomains'
'http://sysctl.org/cameleon/hosts'
'https://zeustracker.abuse.ch/blocklist.php?download=domainblocklist'
'https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt'
'https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt'
'https://hosts-file.net/ad_servers.txt'
'https://raw.githubusercontent.com/quidsup/notrack/master/trackers.txt'
'https://ransomwaretracker.abuse.ch/downloads/RW_DOMBL.txt'
)

declare -a ADBLOCK_SUBSCRIPTION_LIST=(
'https://easylist-downloads.adblockplus.org/easyprivacy.txt'
'https://easylist-downloads.adblockplus.org/easylistchina.txt'
'https://easylist-downloads.adblockplus.org/easylist.txt'
'https://easylist-downloads.adblockplus.org/malwaredomains_full.txt'
'https://easylist-downloads.adblockplus.org/exceptionrules.txt'
)

HOSTS_FILE='/tmp/hosts.dnsmasq'
HOSTS_FILE_CACHE_DIR="${HOSTS_FILE}.cache"

download_blacklist() {
    logger "Downloading $1 to $2"
    wget --no-check-certificate -qO- "$1" | grep -Ev '^[ \t]*#' | grep -oE '[ \t\r\n\v\f]*([a-zA-Z0-9]+[-a-zA-Z0-9]*\.)+[a-zA-Z]{2,}[ \t\r\n\v\f]*' > $2
}

download_blacklist_all() {
    local i=0
    for domain in "$@"; do
        download_blacklist "${domain}" "${HOSTS_FILE_CACHE_DIR}/blacklist-${i}.hosts"
        ((i++))
    done
}

download_adblock_list() {
    logger "Downloading $1 to $2"
    wget --no-check-certificate -qO- "$1" | grep -Ev '^[ \t]*#' > "$2.tmp"
    cat "$2.tmp" | grep -oE '^\|\|[A-Za-z0-9\.-]+\^$' | awk '{print substr($0, 3, length($0)-3)}' > "$2"
    # for exception (whitelist)
    cat "$2.tmp" | grep -oE '^@@\|\|[A-Za-z0-9\.-]+\^$' | awk '{print substr($0, 5, length($0)-5)}' > "$2.exception"
    rm "$2.tmp"
}

download_adblock_list_all() {
    local i=0
    # regular rules
    for domain in "$@"; do
        download_adblock_list "${domain}" "${HOSTS_FILE_CACHE_DIR}/adblock-${i}.hosts"
        ((i++))
    done
}

generate_host() {
    local HOSTS_DIR="$1"
    local HOSTS_DST="$2"
    logger "Generating ${HOSTS_DST} file.."
    find "${HOSTS_DIR}" -name *.hosts -type f -exec awk '!a[$0]++' {} + > ${HOSTS_DST}
    sed -i '' 's/^/0.0.0.0 /' ${HOSTS_DST}
}

main() {
    if [ ! -z "$1" ]; then
        HOSTS_FILE="$1"
    fi

    rm -f ${HOSTS_FILE}
    rm -rf ${HOSTS_FILE_CACHE_DIR}
    mkdir -p ${HOSTS_FILE_CACHE_DIR}

    download_blacklist_all "${DOMAIN_BLACKLIST[@]}"
    download_adblock_list_all "${ADBLOCK_SUBSCRIPTION_LIST[@]}"
    generate_host "${HOSTS_FILE_CACHE_DIR}" "${HOSTS_FILE}"

    rm -rf ${HOSTS_FILE_CACHE_DIR}

    logger "Restarting DNSMasq.."
    logger $(service restart_dnsmasq)
}

# for debugging only, Asuswrt-merlin has this function by default
logger() {
    echo $1
}

main "$@"
