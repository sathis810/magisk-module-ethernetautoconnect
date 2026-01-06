#!/system/bin/sh

# Wait until system is fully booted
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done

LOGFILE="/data/local/tmp/force_eth.log"

# Clear old log and start fresh
echo "========================================" > $LOGFILE
echo "$(date): Ethernet force service started" >> $LOGFILE
echo "========================================" >> $LOGFILE

# Variables to track state changes
LAST_STATE=""
LAST_CARRIER=""
CHECK_COUNT=0

# Main monitoring loop: checks eth0 status every 3 seconds and brings it up if cable is connected
while true; do
    CHECK_COUNT=$((CHECK_COUNT + 1))
    
    if [ -d /sys/class/net/eth0 ]; then
        # Get current status
        CARRIER=$(cat /sys/class/net/eth0/carrier 2>/dev/null)
        STATE=$(cat /sys/class/net/eth0/operstate 2>/dev/null)
        
        # Log only on state changes or every 20 checks (60 seconds)
        if [ "$STATE" != "$LAST_STATE" ] || [ "$CARRIER" != "$LAST_CARRIER" ] || [ $((CHECK_COUNT % 20)) -eq 0 ]; then
            echo "$(date): [Check #$CHECK_COUNT] eth0 | carrier=$CARRIER | state=$STATE" >> $LOGFILE
        fi
        
        # Check if cable is connected (carrier = 1)
        if [ "$CARRIER" = "1" ]; then
            # Force interface up if it's not up
            if [ "$STATE" != "up" ]; then
                echo "$(date): WARNING - Cable connected but interface DOWN! Forcing UP..." >> $LOGFILE
                ip link set eth0 up 2>&1 >> $LOGFILE
                
                # Verify it came up
                sleep 1
                NEW_STATE=$(cat /sys/class/net/eth0/operstate 2>/dev/null)
                echo "$(date): eth0 state after force: $NEW_STATE" >> $LOGFILE
            fi
        elif [ "$CARRIER" != "$LAST_CARRIER" ]; then
            echo "$(date): Cable disconnected" >> $LOGFILE
        fi
        
        # Update last known state
        LAST_STATE="$STATE"
        LAST_CARRIER="$CARRIER"
    else
        if [ "$LAST_STATE" != "notfound" ]; then
            echo "$(date): ERROR - eth0 interface NOT FOUND!" >> $LOGFILE
            LAST_STATE="notfound"
        fi
    fi
    
    sleep 3
done
