#!/system/bin/sh

IFACE="eth0"
LOGFILE="/data/local/tmp/force_eth.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> "$LOGFILE"
}

# Wait until Android is fully booted
log "Waiting for boot completion..."
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done
log "Boot completed"

log "Force Ethernet service started for interface: $IFACE"

while true; do
    if [ ! -d "/sys/class/net/$IFACE" ]; then
        log "Interface $IFACE not present"
        sleep 3
        continue
    fi

    # Carrier state (1 = cable plugged)
    CARRIER=$(cat /sys/class/net/$IFACE/carrier 2>/dev/null)
    [ -z "$CARRIER" ] && CARRIER="unknown"

    # IP check
    IPV4=$(ip -4 addr show $IFACE | awk '/inet / {print $2}')
    HAS_IP=0
    [ -n "$IPV4" ] && HAS_IP=1

    log "State check → carrier=$CARRIER ipv4=$IPV4"

    if [ "$CARRIER" = "1" ] && [ "$HAS_IP" -eq 0 ]; then
        log "Ethernet connected but no IP → restarting EthernetService"

        setprop ctl.restart ethernet
        log "Sent ctl.restart ethernet"

        setprop ctl.restart netd
        log "Sent ctl.restart netd (fallback)"

        sleep 5
    fi

    sleep 3
done
