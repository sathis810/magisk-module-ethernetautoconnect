#!/system/bin/sh

IFACE="eth0"
LOGFILE="/data/local/tmp/force_eth.log"

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

# Function to open Tethering settings and attempt to enable Ethernet
open_tethering_settings() {
    log "Opening Tethering settings UI..."
    
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
    
    # Method 1: Try UIAutomator to find exact position
    log "Attempting to locate Ethernet toggle using UIAutomator..."
    COORDS=$(find_ethernet_toggle_coords)
    
    if [ $? -eq 0 ] && [ -n "$COORDS" ]; then
        TAP_X=$(echo $COORDS | cut -d' ' -f1)
        TAP_Y=$(echo $COORDS | cut -d' ' -f2)
        log "Found Ethernet toggle at coordinates: ${TAP_X},${TAP_Y}"
        
        input tap $TAP_X $TAP_Y 2>/dev/null
        log "Tapped Ethernet toggle"
        sleep 2
        
    else
        log "UIAutomator method failed, using fallback coordinate-based approach..."
        
        # Scroll down to find Ethernet option
        log "Scrolling to find Ethernet option..."
        input swipe $CENTER_X 1500 $CENTER_X 700 400 2>/dev/null
        sleep 1
        
        # Try multiple tap positions based on common layouts
        # Position 1: Lower third of screen (most common)
        TAP_Y1=$(( CENTER_Y + (CENTER_Y / 2) ))
        log "Attempting tap at position: ${CENTER_X},${TAP_Y1}"
        input tap $CENTER_X $TAP_Y1 2>/dev/null
        sleep 2
        
        # Check if toggle was successful by looking for text changes
        # If not, try alternative positions
        
        # Position 2: Middle of screen
        log "Attempting alternative position: ${CENTER_X},${CENTER_Y}"
        input tap $CENTER_X $CENTER_Y 2>/dev/null
        sleep 2
        
        # Position 3: Using DPAD navigation (works on some devices)
        log "Attempting navigation using DPAD keys..."
        for i in 1 2 3 4 5; do
            input keyevent KEYCODE_DPAD_DOWN 2>/dev/null
            sleep 0.3
        done
        input keyevent KEYCODE_ENTER 2>/dev/null
        sleep 1
    fi
    
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

# Wait until Android is fully booted
log "Waiting for boot completion..."
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done
log "Boot completed"

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

    # Reset automation flag if IP is obtained
    if [ "$HAS_IP" -eq 1 ]; then
        if [ "$UI_AUTOMATION_ATTEMPTED" -eq 1 ]; then
            log "✓ Ethernet active with IP: $IPV4"
        fi
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
        # UI automation attempted but still no IP - retry after 5 minutes
        CURRENT_TIME=$(date +%s)
        if [ $((CURRENT_TIME - $LAST_AUTOMATION_TIME)) -gt 300 ]; then
            log "Auto-retry: Resetting automation flag after 5-minute wait..."
            UI_AUTOMATION_ATTEMPTED=0
        else
            log "Waiting for IP assignment or manual intervention..."
            sleep 60
        fi
    fi

    sleep 5
done
