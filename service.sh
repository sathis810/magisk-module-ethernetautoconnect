#!/system/bin/sh
# Ethernet Auto-Connect - Service Script
# Runs on boot and monitors ethernet connection status

MODDIR=${0%/*}
LOGFILE="/data/local/tmp/ethernet_autoconnect.log"
MANAGER="/system/bin/ethernet_manager"

# Wait for boot to complete
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 5
done

# Additional delay to ensure system services are ready
sleep 10

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Ethernet Auto-Connect service starting..." >> "$LOGFILE"

# State tracking
PREV_STATE="disconnected"
ACTIVE_IFACE=""

# Main monitoring loop
while true; do
    # Check ethernet status
    ETH_STATUS=$($MANAGER check)
    CURRENT_STATE=$(echo "$ETH_STATUS" | cut -d':' -f1)
    
    if [ "$CURRENT_STATE" = "connected" ]; then
        CURRENT_IFACE=$(echo "$ETH_STATUS" | cut -d':' -f2)
        
        # Ethernet just connected
        if [ "$PREV_STATE" = "disconnected" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Ethernet connected: $CURRENT_IFACE" >> "$LOGFILE"
            $MANAGER enable "$CURRENT_IFACE"
            ACTIVE_IFACE="$CURRENT_IFACE"
            PREV_STATE="connected"
        fi
    else
        # Ethernet disconnected
        if [ "$PREV_STATE" = "connected" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Ethernet disconnected: $ACTIVE_IFACE" >> "$LOGFILE"
            $MANAGER disable "$ACTIVE_IFACE"
            ACTIVE_IFACE=""
            PREV_STATE="disconnected"
        fi
    fi
    
    # Check every 3 seconds for responsive detection
    sleep 3
done
