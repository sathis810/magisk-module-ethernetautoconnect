#!/system/bin/sh
# Quick test script to verify module functionality on device
# Run this on your Android device via ADB

echo "==================================="
echo "Ethernet Auto-Connect Module Test"
echo "==================================="
echo ""

# Test 1: Check if module is installed
echo "[1] Checking if module is installed..."
if [ -d "/data/adb/modules/ethernet_autoconnect" ]; then
    echo "✓ Module directory found"
else
    echo "✗ Module not installed!"
    exit 1
fi

# Test 2: Check if module is enabled
echo ""
echo "[2] Checking if module is enabled..."
if [ -f "/data/adb/modules/ethernet_autoconnect/disable" ]; then
    echo "✗ Module is DISABLED! Enable it in Magisk Manager"
    exit 1
else
    echo "✓ Module is enabled"
fi

# Test 3: Check if scripts exist
echo ""
echo "[3] Checking if scripts exist..."
if [ -f "/data/adb/modules/ethernet_autoconnect/service.sh" ]; then
    echo "✓ service.sh found"
else
    echo "✗ service.sh not found!"
fi

if [ -f "/system/bin/ethernet_manager" ] || [ -f "/data/adb/modules/ethernet_autoconnect/system/bin/ethernet_manager" ]; then
    echo "✓ ethernet_manager found"
else
    echo "✗ ethernet_manager not found!"
fi

# Test 4: Check script permissions
echo ""
echo "[4] Checking script permissions..."
ls -la /data/adb/modules/ethernet_autoconnect/service.sh
ls -la /system/bin/ethernet_manager 2>/dev/null || ls -la /data/adb/modules/ethernet_autoconnect/system/bin/ethernet_manager

# Test 5: Check if service is running
echo ""
echo "[5] Checking if service is running..."
if ps -A | grep -q "service.sh"; then
    echo "✓ Service process found:"
    ps -A | grep "service.sh"
else
    echo "⚠ Service process not found (may not have rebooted yet)"
fi

# Test 6: Check log file
echo ""
echo "[6] Checking log file..."
if [ -f "/data/local/tmp/ethernet_autoconnect.log" ]; then
    echo "✓ Log file exists"
    echo ""
    echo "Last 20 lines of log:"
    echo "---"
    tail -n 20 /data/local/tmp/ethernet_autoconnect.log
    echo "---"
elif [ -f "/sdcard/ethernet_autoconnect.log" ]; then
    echo "✓ Log file exists (at /sdcard)"
    echo ""
    echo "Last 20 lines of log:"
    echo "---"
    tail -n 20 /sdcard/ethernet_autoconnect.log
    echo "---"
else
    echo "✗ No log file found! Service may not be running"
fi

# Test 7: Check ethernet interfaces
echo ""
echo "[7] Checking ethernet interfaces..."
echo "Available network interfaces:"
ls /sys/class/net/

echo ""
echo "Checking eth0:"
if [ -d "/sys/class/net/eth0" ]; then
    echo "✓ eth0 exists"
    CARRIER=$(cat /sys/class/net/eth0/carrier 2>/dev/null || echo "unknown")
    echo "  Carrier status: $CARRIER (1=connected, 0=disconnected)"
else
    echo "✗ eth0 not found"
fi

echo ""
echo "Checking eth1:"
if [ -d "/sys/class/net/eth1" ]; then
    echo "✓ eth1 exists"
    CARRIER=$(cat /sys/class/net/eth1/carrier 2>/dev/null || echo "unknown")
    echo "  Carrier status: $CARRIER (1=connected, 0=disconnected)"
else
    echo "⚠ eth1 not found (may not exist on this device)"
fi

# Test 8: Check DHCP client availability
echo ""
echo "[8] Checking DHCP client availability..."
which dhcpcd 2>/dev/null && echo "✓ dhcpcd available" || echo "✗ dhcpcd not found"
which dhcptool 2>/dev/null && echo "✓ dhcptool available" || echo "✗ dhcptool not found"
which netcfg 2>/dev/null && echo "✓ netcfg available" || echo "✗ netcfg not found"

# Test 9: Test manager script manually
echo ""
echo "[9] Testing manager script manually..."
MANAGER_PATH="/system/bin/ethernet_manager"
[ ! -f "$MANAGER_PATH" ] && MANAGER_PATH="/data/adb/modules/ethernet_autoconnect/system/bin/ethernet_manager"

if [ -f "$MANAGER_PATH" ]; then
    echo "Running: $MANAGER_PATH check"
    $MANAGER_PATH check
else
    echo "✗ Cannot find ethernet_manager to test"
fi

echo ""
echo "==================================="
echo "Test complete!"
echo "==================================="
