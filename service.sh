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

# Track restart attempts to prevent excessive restarts
RESTART_COUNT=0
MAX_RESTARTS=3
LAST_RESTART_TIME=0

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

    # Reset restart counter if IP is obtained
    if [ "$HAS_IP" -eq 1 ]; then
        RESTART_COUNT=0
    fi

    # Only attempt restart if conditions are met and we haven't exceeded max restarts
    if [ "$CARRIER" = "1" ] && [ "$HAS_IP" -eq 0 ] && [ "$RESTART_COUNT" -lt "$MAX_RESTARTS" ]; then
        CURRENT_TIME=$(date +%s)
        TIME_SINCE_LAST=$(($CURRENT_TIME - $LAST_RESTART_TIME))
        
        # Only restart if at least 30 seconds have passed since last restart
        if [ "$TIME_SINCE_LAST" -gt 30 ] || [ "$LAST_RESTART_TIME" -eq 0 ]; then
            log "Ethernet connected but no IP → enabling ethernet tethering (attempt $((RESTART_COUNT + 1))/$MAX_RESTARTS)"
            
            # Enable ethernet tethering using Android connectivity command
            cmd connectivity tether ethernet on 2>/dev/null || cmd connectivity tethering ethernet on 2>/dev/null
            log "Enabled Ethernet tethering via connectivity command"
            
            # Alternative method using ndc (network daemon control)
            ndc tether interface add $IFACE 2>/dev/null
            log "Added $IFACE to tethering via ndc"
            
            # Bring interface up manually
            ip link set $IFACE up 2>/dev/null
            log "Brought $IFACE interface up"
            
            # Request DHCP if available
            dhcpcd $IFACE 2>/dev/null &
            log "Requested DHCP for $IFACE"
            
            RESTART_COUNT=$((RESTART_COUNT + 1))
            LAST_RESTART_TIME=$CURRENT_TIME
            
            # Wait longer after restart to give service time to stabilize
            sleep 15
        else
            log "Skipping restart - cooldown period not elapsed"
        fi
    elif [ "$RESTART_COUNT" -ge "$MAX_RESTARTS" ]; then
        log "Max restart attempts reached. Manual intervention may be required."
    fi

    sleep 5
done
