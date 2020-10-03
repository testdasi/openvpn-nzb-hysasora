#!/bin/bash

### Only run process if ovpn found ###
if [[ -f "/config/openvpn/openvpn.ovpn" ]]
then
    echo '[info] Config file detected...'
    ### Set various variable values ###
    echo ''
    echo '[info] Setting variables'
    source /set_variables.sh
    echo '[info] All variables set'

    ### Fixing config files ###
    echo ''
    echo '[info] Fixing configs'
    source /fix_config.sh
    echo '[info] All configs fixed'

    ### Stubby DNS-over-TLS ###
    echo ''
    echo "[info] Run stubby in background on port $DNS_PORT"
    stubby -g -C /config/stubby/stubby.yml
    ipnaked=$(dig +short myip.opendns.com @208.67.222.222)
    echo "[warn] Your ISP public IP is $ipnaked"

    ### nftables ###
    echo ''
    echo '[info] Set up nftables rules'
    source /nftables.sh
    echo '[info] All rules created'

    ### OpenVPN ###
    echo ''
    echo "[info] Setting up OpenVPN tunnel"
    source /static/scripts/openvpn.sh
    echo '[info] Done'

    ### Dante SOCKS proxy to VPN ###
    echo ''
    echo "[info] Run danted in background on port $DANTE_PORT"
    danted -D -f /config/dante/danted.conf

    ### Tinyproxy HTTP proxy to VPN ###
    echo ''
    echo "[info] Run tinyproxy in background with no log on port $TINYPROXY_PORT"
    tinyproxy -c /config/tinyproxy/tinyproxy.conf

    ### sabnzbdplus
    echo ''
    echo "[info] Run sabnzbdplus in background on HTTP port $SAB_PORT_A and HTTPS port $SAB_PORT_B"
    sabnzbdplus --daemon --config-file /config/sabnzbdplus/sabnzbdplus.ini --pidfile /config/sabnzbdplus/sabnzbd.pid

    ### deluge
    echo ''
    echo "[info] Run deluge in background on HTTP port $DELUGE_PORT"
    deluged --quiet --port=58846 --config=/config/deluge-web
    deluge-web --fork --quiet --config=/config/deluge-web

    ### nzbhydra2
    echo ''
    echo "[info] Run nzbhydra2 in background on port $HYDRA_PORT"
    /app/nzbhydra2/nzbhydra2 --daemon --nobrowser --java /usr/lib/jvm/java-11-openjdk-amd64/bin/java --datafolder /config/nzbhydra2 --pidfile /config/nzbhydra2/nzbhydra2.pid

    ### GUI launcher
    echo ''
    echo "[info] Run GUI launcher in background at $LAUNCHER_IP:$LAUNCHER_PORT"
    start-stop-daemon --start --background --name launcher --chdir /app/launcher --exec /app/launcher/launcher-python3.sh

    ### Periodically checking IP ###
    sleep_time=3600
    echo ''
    while true
    do
        iphiden=$(dig +short myip.opendns.com @208.67.222.222)
        echo "[info] Your VPN public IP is $iphiden"
        sleep $sleep_time
    done
else
    echo '[CRITICAL] Config file not found, quitting...'
fi
