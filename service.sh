#!/system/bin/sh
# Ethernet Auto-Connect - Service Script
# Runs on boot and monitors ethernet connection status

MODDIR=${0%/*}
LOGFILE="/data/local/tmp/ethernet_autoconnect.log"
MANAGER="/system/bin/ethernet_manager"

# Create log file if it doesn't exist
touch "$LOGFILE" 2>/dev/null || LOGFILE="/sdcard/ethernet_autoconnect.log"

# Redirect all output to log for debugging
exec >> "$LOGFILE" 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ========================================" 
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Ethernet Auto-Connect service initializing..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Module directory: $MODDIR"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Manager script: $MANAGER"

# Check if manager script exists and is executable
if [ ! -f "$MANAGER" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Manager script not found at $MANAGER"
    exit 1
fi

if [ ! -x "$MANAGER" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: Manager script not executable, attempting to fix..."
    chmod 755 "$MANAGER" 2>/dev/null
fi

# Wait for boot to complete
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Waiting for boot to complete..."
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 5
done

# Additional delay to ensure system services are ready
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Boot completed. Waiting for system services..."
sleep 10

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting ethernet monitoring loop..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Android version: $(getprop ro.build.version.release)"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Device: $(getprop ro.product.model)"

# List available network interfaces
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Available network interfaces:"
ls /sys/class/net/ 2>/dev/null | while read iface; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]   - $iface"
done

# State tracking
PREV_STATE="disconnected"
ACTIVE_IFACE=""
CHECK_COUNT=0

# Main monitoring loop
while true; do
    CHECK_COUNT=$((CHECK_COUNT + 1))
    
    # Log periodic heartbeat (every 20 checks = 1 minute)
    if [ $((CHECK_COUNT % 20)) -eq 0 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Heartbeat - checks: $CHECK_COUNT, state: $PREV_STATE"
    fi
    
    # Check ethernet status
    ETH_STATUS=$($MANAGER check 2>&1)
    if [ $? -ne 0 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: Manager check failed: $ETH_STATUS"
        sleep 3
        continue
    fi
    
    CURRENT_STATE=$(echo "$ETH_STATUS" | cut -d':' -f1)
    
    if [ "$CURRENT_STATE" = "connected" ]; then
        CURRENT_IFACE=$(echo "$ETH_STATUS" | cut -d':' -f2)
        
        # Ethernet just connected
        if [ "$PREV_STATE" = "disconnected" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] *** Ethernet cable connected: $CURRENT_IFACE ***"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Enabling ethernet and disabling WiFi..."
            $MANAGER enable "$CURRENT_IFACE" 2>&1
            ACTIVE_IFACE="$CURRENT_IFACE"
            PREV_STATE="connected"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Ethernet activation complete"
        fi
    else
        # Ethernet disconnected
        if [ "$PREV_STATE" = "connected" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] *** Ethernet cable disconnected: $ACTIVE_IFACE ***"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Disabling ethernet and enabling WiFi..."
            $MANAGER disable "$ACTIVE_IFACE" 2>&1
            ACTIVE_IFACE=""
            PREV_STATE="disconnected"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Ethernet deactivation complete"
        fi
    fi
    
    # Check every 3 seconds for responsive detection
    sleep 3
done
