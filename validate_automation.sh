#!/system/bin/sh

# Validation script to test Ethernet automation logic
# Run this on your Android device to verify functionality

echo "======================================"
echo "Ethernet Automation Validation"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Check eth0 interface
echo "[TEST 1] Checking eth0 interface..."
if [ -d "/sys/class/net/eth0" ]; then
    echo "✓ eth0 interface exists"
else
    echo "✗ eth0 interface NOT found - This device may not have Ethernet hardware"
    echo "  Available interfaces:"
    ls /sys/class/net/
fi
echo ""

# Test 2: Check carrier detection
echo "[TEST 2] Checking carrier detection..."
if [ -f "/sys/class/net/eth0/carrier" ]; then
    CARRIER=$(cat /sys/class/net/eth0/carrier 2>/dev/null)
    if [ "$CARRIER" = "1" ]; then
        echo "✓ Ethernet cable CONNECTED (carrier=1)"
    elif [ "$CARRIER" = "0" ]; then
        echo "⚠ Ethernet cable DISCONNECTED (carrier=0)"
        echo "  Please connect an Ethernet cable to test"
    else
        echo "⚠ Carrier status unknown: $CARRIER"
    fi
else
    echo "✗ Cannot read carrier status"
fi
echo ""

# Test 3: Check IP address
echo "[TEST 3] Checking IP address..."
IPV4=$(ip -4 addr show eth0 2>/dev/null | awk '/inet / {print $2}')
if [ -n "$IPV4" ]; then
    echo "✓ IP address assigned: $IPV4"
else
    echo "⚠ No IP address assigned"
    echo "  This is normal if cable just connected or DHCP not complete"
fi
echo ""

# Test 4: Check required commands
echo "[TEST 4] Checking required commands..."

# Check cmd connectivity
if cmd connectivity --help >/dev/null 2>&1; then
    echo "✓ 'cmd connectivity' available"
else
    echo "⚠ 'cmd connectivity' not available"
fi

# Check ndc
if command -v ndc >/dev/null 2>&1; then
    echo "✓ 'ndc' command available"
else
    echo "⚠ 'ndc' command not found"
fi

# Check dhcpcd
if command -v dhcpcd >/dev/null 2>&1; then
    echo "✓ 'dhcpcd' available"
else
    echo "⚠ 'dhcpcd' not found - DHCP may use alternative method"
fi

# Check uiautomator
if command -v uiautomator >/dev/null 2>&1; then
    echo "✓ 'uiautomator' available (UI automation will work)"
else
    echo "⚠ 'uiautomator' not found - will use fallback tap methods"
fi

echo ""

# Test 5: Check screen resolution
echo "[TEST 5] Checking screen resolution..."
WM_SIZE=$(wm size 2>/dev/null | grep "Physical size" | cut -d: -f2 | tr -d ' ')
if [ -n "$WM_SIZE" ]; then
    WIDTH=$(echo $WM_SIZE | cut -dx -f1)
    HEIGHT=$(echo $WM_SIZE | cut -dx -f2)
    CENTER_X=$((WIDTH / 2))
    CENTER_Y=$((HEIGHT / 2))
    echo "✓ Screen: ${WIDTH}x${HEIGHT}"
    echo "  Center point: ${CENTER_X},${CENTER_Y}"
else
    echo "⚠ Could not detect screen resolution"
    echo "  Will use default 1080x1920"
fi
echo ""

# Test 6: Test Settings Activity
echo "[TEST 6] Testing Settings activities..."
echo "Attempting to open Tethering settings (will close automatically)..."

am start -a android.settings.TETHER_SETTINGS 2>/dev/null
RESULT=$?
sleep 2
input keyevent KEYCODE_BACK 2>/dev/null

if [ $RESULT -eq 0 ]; then
    echo "✓ Can open Tethering settings"
else
    echo "⚠ Tethering settings access issue - will try alternatives"
fi
echo ""

# Test 7: Test input commands
echo "[TEST 7] Testing input commands..."
if input --help >/dev/null 2>&1; then
    echo "✓ 'input' command available"
else
    echo "✗ 'input' command not found - UI automation will NOT work"
fi
echo ""

# Summary
echo "======================================"
echo "SUMMARY"
echo "======================================"

READY=true

if [ ! -d "/sys/class/net/eth0" ]; then
    echo "❌ CRITICAL: eth0 interface not found"
    READY=false
fi

if ! command -v input >/dev/null 2>&1; then
    echo "❌ CRITICAL: 'input' command not available"
    READY=false
fi

if [ "$READY" = true ]; then
    echo "✅ Device is READY for Ethernet automation!"
    echo ""
    echo "The module will:"
    echo "  1. Monitor eth0 continuously"
    echo "  2. Detect when cable is connected"
    echo "  3. Try command-line methods first"
    echo "  4. Fall back to UI automation if needed"
    echo ""
    echo "To monitor logs after installation:"
    echo "  tail -f /data/local/tmp/force_eth.log"
else
    echo "⚠️  Some features may not work as expected"
    echo "    Review the warnings above"
fi

echo ""
echo "======================================"

