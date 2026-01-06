#!/system/bin/sh

# Test script for UI automation - helps you find correct tap coordinates
# Run this script to test opening settings and finding the right position

echo "=== Ethernet UI Automation Test ==="
echo ""

# Get screen resolution
echo "Detecting screen resolution..."
WM_SIZE=$(wm size 2>/dev/null | grep "Physical size" | cut -d: -f2 | tr -d ' ')

if [ -n "$WM_SIZE" ]; then
    WIDTH=$(echo $WM_SIZE | cut -dx -f1)
    HEIGHT=$(echo $WM_SIZE | cut -dx -f2)
    echo "Screen Resolution: ${WIDTH}x${HEIGHT}"
else
    echo "Could not detect screen resolution"
    WIDTH=1080
    HEIGHT=1920
    echo "Using default: ${WIDTH}x${HEIGHT}"
fi

echo ""
echo "=== Step 1: Opening Tethering Settings ==="
echo "This will open the tethering settings page..."
sleep 2

# Try different methods to open settings
am start -a android.settings.TETHER_SETTINGS 2>/dev/null
RESULT1=$?

sleep 2

if [ $RESULT1 -ne 0 ]; then
    echo "Method 1 failed, trying alternative..."
    am start -n com.android.settings/.TetherSettings 2>/dev/null
    sleep 2
fi

echo ""
echo "=== Step 2: Manual Coordinate Detection ==="
echo "The tethering settings should now be open."
echo "Please note the position of the Ethernet tethering toggle."
echo ""
echo "To find exact coordinates:"
echo "1. Take a screenshot (Power + Volume Down)"
echo "2. Or use: screencap -p /sdcard/screen.png"
echo "3. Transfer to PC and measure pixel position"
echo ""
echo "Common positions for ${WIDTH}x${HEIGHT}:"
CENTER_X=$((WIDTH / 2))
echo "  X (horizontal center): $CENTER_X"
echo "  Y positions to try:"
echo "    - Upper third: $((HEIGHT / 3))"
echo "    - Middle: $((HEIGHT / 2))"
echo "    - Lower third: $((HEIGHT * 2 / 3))"
echo ""

# Wait for user to observe
echo "Waiting 10 seconds for you to observe the screen..."
sleep 10

echo ""
echo "=== Step 3: Testing tap positions ==="
echo "Will attempt taps at common positions..."

# Test position 1 - Upper area
TAP_Y1=$((HEIGHT * 30 / 100))
echo "Testing position: $CENTER_X, $TAP_Y1"
input tap $CENTER_X $TAP_Y1 2>/dev/null
sleep 3

# Go back if something was clicked
input keyevent KEYCODE_BACK 2>/dev/null
sleep 1

# Reopen settings
am start -a android.settings.TETHER_SETTINGS 2>/dev/null
sleep 2

# Test position 2 - Middle-upper area
TAP_Y2=$((HEIGHT * 50 / 100))
echo "Testing position: $CENTER_X, $TAP_Y2"
input tap $CENTER_X $TAP_Y2 2>/dev/null
sleep 3

input keyevent KEYCODE_BACK 2>/dev/null
sleep 1

am start -a android.settings.TETHER_SETTINGS 2>/dev/null
sleep 2

# Test position 3 - Lower area
TAP_Y3=$((HEIGHT * 70 / 100))
echo "Testing position: $CENTER_X, $TAP_Y3"
input tap $CENTER_X $TAP_Y3 2>/dev/null
sleep 3

echo ""
echo "=== Step 4: UI Automator Dump (Advanced) ==="
echo "Attempting to dump UI hierarchy..."

uiautomator dump /data/local/tmp/ui_test_dump.xml 2>/dev/null

if [ -f /data/local/tmp/ui_test_dump.xml ]; then
    echo "UI dump successful! Searching for Ethernet..."
    
    # Search for ethernet-related elements
    grep -i "ethernet" /data/local/tmp/ui_test_dump.xml > /data/local/tmp/ethernet_elements.txt 2>/dev/null
    
    if [ -s /data/local/tmp/ethernet_elements.txt ]; then
        echo "Found Ethernet elements:"
        cat /data/local/tmp/ethernet_elements.txt
        echo ""
        echo "Full dump saved to: /data/local/tmp/ui_test_dump.xml"
        echo "Ethernet elements saved to: /data/local/tmp/ethernet_elements.txt"
    else
        echo "No Ethernet elements found in UI hierarchy"
    fi
else
    echo "UI dump failed - uiautomator may not be available"
fi

echo ""
echo "=== Test Complete ==="
echo "Going back to home screen..."
input keyevent KEYCODE_HOME 2>/dev/null

echo ""
echo "Results:"
echo "- Check which tap position worked (if any)"
echo "- Update service.sh with the correct coordinates"
echo "- Look at /data/local/tmp/ethernet_elements.txt for exact positions"

