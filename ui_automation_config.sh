#!/system/bin/sh

# UI Automation Configuration for Ethernet Tethering
# Customize these values based on your device's screen resolution and UI layout

# Get screen resolution automatically
get_screen_info() {
    WM_SIZE=$(wm size 2>/dev/null | grep "Physical size" | cut -d: -f2 | tr -d ' ')
    if [ -n "$WM_SIZE" ]; then
        SCREEN_WIDTH=$(echo $WM_SIZE | cut -dx -f1)
        SCREEN_HEIGHT=$(echo $WM_SIZE | cut -dx -f2)
    else
        # Default to 1080x1920 if detection fails
        SCREEN_WIDTH=1080
        SCREEN_HEIGHT=1920
    fi
    
    echo "Screen: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}" >> /data/local/tmp/force_eth.log
}

# Function to enable Ethernet via UI automation with custom coordinates
enable_ethernet_ui() {
    get_screen_info
    
    # Calculate relative positions (adjust these percentages based on your device)
    CENTER_X=$((SCREEN_WIDTH / 2))
    
    # Typical Ethernet tethering toggle position (adjust these values)
    # Usually around 80% from top on most Android devices
    ETHERNET_TOGGLE_Y=$((SCREEN_HEIGHT * 80 / 100))
    
    # Open Tethering Settings
    am start -a android.settings.TETHER_SETTINGS 2>/dev/null || \
    am start -n com.android.settings/.TetherSettings 2>/dev/null || \
    am start -a android.settings.WIRELESS_SETTINGS 2>/dev/null
    
    sleep 4
    
    # Scroll to find Ethernet option (if needed)
    input swipe $CENTER_X 1500 $CENTER_X 800 300 2>/dev/null
    sleep 2
    
    # Tap on Ethernet tethering toggle
    input tap $CENTER_X $ETHERNET_TOGGLE_Y 2>/dev/null
    echo "$(date '+%Y-%m-%d %H:%M:%S') | Tapped at: ${CENTER_X},${ETHERNET_TOGGLE_Y}" >> /data/local/tmp/force_eth.log
    
    sleep 2
    
    # Go back to home
    input keyevent KEYCODE_HOME 2>/dev/null
}

# Alternative method using accessibility service tap coordinates
# For devices where you know exact pixel positions
enable_ethernet_exact_coords() {
    # Replace these with exact coordinates from your device
    # You can find these using: adb shell getevent -l
    # Or by taking a screenshot and measuring positions
    
    ETHERNET_SETTING_X=540  # Adjust for your device
    ETHERNET_SETTING_Y=800  # Adjust for your device
    
    am start -a android.settings.TETHER_SETTINGS 2>/dev/null
    sleep 3
    
    input tap $ETHERNET_SETTING_X $ETHERNET_SETTING_Y 2>/dev/null
    sleep 2
    
    input keyevent KEYCODE_HOME 2>/dev/null
}

# Method using UI Automator dump for finding elements (requires root)
enable_ethernet_uiautomator() {
    # Dump UI hierarchy
    uiautomator dump /data/local/tmp/ui_dump.xml 2>/dev/null
    
    if [ -f /data/local/tmp/ui_dump.xml ]; then
        # Try to find Ethernet toggle coordinates from XML
        # This is more reliable but requires parsing XML
        COORDS=$(grep -i "ethernet" /data/local/tmp/ui_dump.xml | grep -oP 'bounds="\[\K[0-9,\[\]]+' | head -1)
        
        if [ -n "$COORDS" ]; then
            # Parse coordinates and tap
            # Format is [left,top][right,bottom]
            echo "Found Ethernet toggle at: $COORDS" >> /data/local/tmp/force_eth.log
        fi
        
        rm /data/local/tmp/ui_dump.xml
    fi
}

