#!/system/bin/sh

IFACE="eth0"
LOGFILE="/data/local/tmp/force_eth.log"

# Function to check and delete log file if it exceeds 10KB
check_and_rotate_log() {
    if [ -f "$LOGFILE" ]; then
        # Get file size in bytes
        LOG_SIZE=$(stat -c%s "$LOGFILE" 2>/dev/null || stat -f%z "$LOGFILE" 2>/dev/null)
        # 10KB = 10240 bytes
        if [ -n "$LOG_SIZE" ] && [ "$LOG_SIZE" -gt 10240 ]; then
            rm -f "$LOGFILE"
        fi
    fi
}

# Function to log messages with timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> "$LOGFILE"
}

# Function to find Ethernet toggle using UIAutomator
find_ethernet_toggle_coords() {
    uiautomator dump /data/local/tmp/ui_dump.xml 2>/dev/null
    
    if [ -f /data/local/tmp/ui_dump.xml ]; then
        # Search for Ethernet-related elements
        # Extract bounds attribute - format: bounds="[left,top][right,bottom]"
        ETHERNET_LINE=$(grep -i "ethernet" /data/local/tmp/ui_dump.xml | head -1)
        
        if [ -n "$ETHERNET_LINE" ]; then
            # Extract bounds using sed (more compatible than grep -P)
            BOUNDS=$(echo "$ETHERNET_LINE" | sed -n 's/.*bounds="\[\([0-9]*\),\([0-9]*\)\]\[\([0-9]*\),\([0-9]*\)\]\".*/\1 \2 \3 \4/p')
            
            if [ -n "$BOUNDS" ]; then
                # Parse coordinates
                LEFT=$(echo "$BOUNDS" | cut -d' ' -f1)
                TOP=$(echo "$BOUNDS" | cut -d' ' -f2)
                RIGHT=$(echo "$BOUNDS" | cut -d' ' -f3)
                BOTTOM=$(echo "$BOUNDS" | cut -d' ' -f4)
                
                # Calculate center point for tap
                TAP_X=$(( (LEFT + RIGHT) / 2 ))
                TAP_Y=$(( (TOP + BOTTOM) / 2 ))
                
                log "UIAutomator found bounds: [$LEFT,$TOP][$RIGHT,$BOTTOM]"
                echo "$TAP_X $TAP_Y"
                rm /data/local/tmp/ui_dump.xml
                return 0
            fi
        fi
        rm /data/local/tmp/ui_dump.xml
    fi
    
    return 1
}

# Function to wake up screen if it's off
wake_screen() {
    # Check if screen is off
    SCREEN_STATE=$(dumpsys power | grep "Display Power: state=" | cut -d'=' -f2)
    
    if [ "$SCREEN_STATE" = "OFF" ] || [ -z "$SCREEN_STATE" ]; then
        log "Screen is OFF - waking up screen..."
        
        # Wake up the screen
        input keyevent KEYCODE_WAKEUP 2>/dev/null
        sleep 1
               
        log "Screen woken up and unlock attempted"
        return 0
    else
        log "Screen is already ON (state: $SCREEN_STATE)"
        return 1
    fi
}

# Function to open Tethering settings and attempt to enable Ethernet
open_tethering_settings() {
    log "Opening Tethering settings UI..."
    
    # Ensure screen is on before UI automation
    wake_screen
    
    # Get screen resolution for dynamic positioning
    SCREEN_INFO=$(get_screen_center)
    CENTER_X=$(echo $SCREEN_INFO | cut -d' ' -f1)
    CENTER_Y=$(echo $SCREEN_INFO | cut -d' ' -f2)
    
    log "Screen center: ${CENTER_X}x${CENTER_Y}"
    
    # Try different settings activities based on Android version
    # Method 1: Direct tethering settings
    am start -a android.settings.TETHER_SETTINGS 2>/dev/null
    RESULT=$?
    sleep 3
    
    # If that fails, try component name
    if [ $RESULT -ne 0 ]; then
        log "Method 1 failed, trying alternative..."
        am start -n com.android.settings/.TetherSettings 2>/dev/null
        sleep 3
    fi
    
    # If still fails, try wireless settings
    if [ $? -ne 0 ]; then
        log "Method 2 failed, trying wireless settings..."
        am start -a android.settings.WIRELESS_SETTINGS 2>/dev/null
        sleep 3
    fi
    
    log "Settings opened, waiting for UI to stabilize..."
    sleep 2
    
    # Hardcoded toggle coordinates for Ethernet switch
    TAP_X=610
    TAP_Y=1810
    
    log "Tapping Ethernet toggle at hardcoded coordinates: ${TAP_X},${TAP_Y}"
    input tap $TAP_X $TAP_Y 2>/dev/null
    log "Tapped Ethernet toggle"
    sleep 2
    
    log "UI automation completed, returning to home..."
    sleep 1
    
    # Return to home screen
    input keyevent KEYCODE_HOME 2>/dev/null
    
    log "UI automation sequence finished"
}

# Function to check if IP address was successfully obtained after UI automation
verify_ip_obtained() {
    sleep 5  # Wait for DHCP
    
    for i in 1 2 3 4 5; do
        IPV4=$(ip -4 addr show $IFACE | awk '/inet / {print $2}')
        if [ -n "$IPV4" ]; then
            log "✓ IP address obtained: $IPV4"
            return 0
        fi
        sleep 2
    done
    
    log "✗ No IP address obtained after UI automation"
    return 1
}

# Function to get screen resolution for dynamic tap positioning
get_screen_center() {
    WM_SIZE=$(wm size 2>/dev/null | grep "Physical size" | cut -d: -f2 | tr -d ' ')
    if [ -n "$WM_SIZE" ]; then
        WIDTH=$(echo $WM_SIZE | cut -dx -f1)
        HEIGHT=$(echo $WM_SIZE | cut -dx -f2)
        CENTER_X=$((WIDTH / 2))
        CENTER_Y=$((HEIGHT / 2))
        echo "$CENTER_X $CENTER_Y"
    else
        echo "540 960" # Default for 1080p
    fi
}

# Check and rotate log file if it exceeds 10KB before starting new logs
check_and_rotate_log

# Wait until Android is fully booted
log "Waiting for boot completion..."
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done
log "Boot completed"

# Wait additional 10 seconds for all system services to fully initialize
log "Waiting 10 seconds for system services to stabilize..."
sleep 10

log "========================================="
log "Force Ethernet UI Automation Service Started"
log "Interface: $IFACE"
log "Mode: UI AUTOMATION ONLY"
log "========================================="

# Track UI automation attempts
LAST_AUTOMATION_TIME=0
UI_AUTOMATION_ATTEMPTED=0

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

    # Reset automation flag if IP is obtained OR cable is disconnected
    if [ "$HAS_IP" -eq 1 ]; then
        if [ "$UI_AUTOMATION_ATTEMPTED" -eq 1 ]; then
            log "✓ Ethernet active with IP: $IPV4"
        fi
        UI_AUTOMATION_ATTEMPTED=0
    elif [ "$CARRIER" != "1" ] && [ "$UI_AUTOMATION_ATTEMPTED" -eq 1 ]; then
        # Reset flag when cable is disconnected (allows retry on reconnection)
        log "Cable disconnected - resetting automation flag"
        UI_AUTOMATION_ATTEMPTED=0
    fi

    # UI Automation: Trigger when cable connected but no IP
    if [ "$CARRIER" = "1" ] && [ "$HAS_IP" -eq 0 ] && [ "$UI_AUTOMATION_ATTEMPTED" -eq 0 ]; then
        CURRENT_TIME=$(date +%s)
        TIME_SINCE_LAST=$(($CURRENT_TIME - $LAST_AUTOMATION_TIME))
        
        # Wait at least 10 seconds between UI automation attempts
        if [ "$TIME_SINCE_LAST" -gt 10 ] || [ "$LAST_AUTOMATION_TIME" -eq 0 ]; then
            log "========================================="
            log "TRIGGER: Ethernet cable detected but no IP"
            log "Starting UI automation sequence..."
            log "========================================="
            
            LAST_AUTOMATION_TIME=$CURRENT_TIME
            open_tethering_settings
            
            # Verify if UI automation was successful
            if verify_ip_obtained; then
                log "✓ SUCCESS: UI automation enabled Ethernet!"
                UI_AUTOMATION_ATTEMPTED=1
            else
                log "✗ FAILED: No IP assignment after UI automation"
                log "Possible causes:"
                log "  → Toggle not found/clicked correctly"
                log "  → DHCP server not responding on network"
                log "  → Manual settings configuration required"
                UI_AUTOMATION_ATTEMPTED=1
            fi
            
            sleep 30
        else
            log "Cooldown active - waiting before next attempt..."
        fi
    elif [ "$UI_AUTOMATION_ATTEMPTED" -eq 1 ] && [ "$HAS_IP" -eq 0 ]; then
        # UI automation attempted but still no IP - retry after 1 minute
        CURRENT_TIME=$(date +%s)
        if [ $((CURRENT_TIME - $LAST_AUTOMATION_TIME)) -gt 60 ]; then
            log "Auto-retry: Resetting automation flag after 1-minute wait..."
            UI_AUTOMATION_ATTEMPTED=0
        else
            log "Waiting for IP assignment or manual intervention..."
            sleep 60
        fi
    fi

    sleep 5
done
