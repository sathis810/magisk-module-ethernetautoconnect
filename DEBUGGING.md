# Debugging Guide for Ethernet Auto-Connect Module

## Common Issues & Solutions

### 1. **Line Ending Issues (CRITICAL)**
**Problem:** Scripts created on Windows have CRLF (`\r\n`) line endings instead of Unix LF (`\n`), causing "bad interpreter" or "command not found" errors on Android.

**Fix:** Convert all `.sh` files to Unix line endings before packaging:
```bash
# On Windows PowerShell:
(Get-Content "filename.sh" -Raw) -replace "`r`n", "`n" | Set-Content "filename.sh" -NoNewline
```

**Files to check:**
- `service.sh`
- `system/bin/ethernet_manager`
- `install.sh`
- `uninstall.sh`

---

### 2. **Check if Module is Running**
After installing and rebooting, check if the service is actually running:

```bash
# Via ADB
adb shell

# Check if the service process is running
ps -A | grep service.sh
ps -A | grep ethernet

# Check the log file
cat /data/local/tmp/ethernet_autoconnect.log

# Check if log file exists
ls -la /data/local/tmp/ethernet_autoconnect.log
```

---

### 3. **Verify Magisk Module is Enabled**
```bash
# Check if module is installed
adb shell ls /data/adb/modules/ethernet_autoconnect

# Check if module is enabled (no 'disable' file)
adb shell ls /data/adb/modules/ethernet_autoconnect/disable
# Should return "No such file or directory"

# Check module is loaded
adb shell magisk --list
```

---

### 4. **Check Ethernet Interface**
```bash
# List all network interfaces
adb shell ip link show
# or
adb shell ifconfig

# Check if eth0/eth1 exists
adb shell ls /sys/class/net/

# Check carrier status (should be 1 when cable connected)
adb shell cat /sys/class/net/eth0/carrier
```

---

### 5. **Manual Testing**
Test the ethernet_manager script manually:

```bash
adb shell

# Make sure script is executable
chmod 755 /system/bin/ethernet_manager

# Test check function
/system/bin/ethernet_manager check

# Test enable function (replace eth0 with your interface)
/system/bin/ethernet_manager enable eth0

# Check if IP was assigned
ip addr show eth0
```

---

### 6. **Check SELinux Permissions**
SELinux might be blocking the scripts:

```bash
# Check SELinux status
adb shell getenforce
# If "Enforcing", try setting to Permissive for testing
adb shell su -c setenforce 0

# Check denials in log
adb shell dmesg | grep avc
adb logcat -d | grep avc | grep ethernet
```

---

### 7. **Check DHCP Availability**
```bash
# Check which DHCP client is available
adb shell which dhcpcd
adb shell which dhcptool
adb shell which netcfg

# Test DHCP manually
adb shell su
dhcpcd -n eth0
```

---

### 8. **Check Service.sh Startup**
```bash
# Check if boot is completed
adb shell getprop sys.boot_completed
# Should return "1"

# Manually start service for testing
adb shell su -c /data/adb/modules/ethernet_autoconnect/service.sh &

# Monitor log in real-time
adb shell tail -f /data/local/tmp/ethernet_autoconnect.log
```

---

### 9. **Common Errors & Fixes**

#### Error: "bad interpreter: /system/bin/sh^M"
**Cause:** Windows line endings (CRLF)
**Fix:** Convert to Unix line endings (see #1 above)

#### Error: Permission denied
**Cause:** Script not executable
**Fix:**
```bash
adb shell su
chmod 755 /data/adb/modules/ethernet_autoconnect/service.sh
chmod 755 /data/adb/modules/ethernet_autoconnect/system/bin/ethernet_manager
```

#### Error: No log file created
**Cause:** Service script not running or no write permission
**Fix:**
```bash
# Create log directory manually
adb shell mkdir -p /data/local/tmp
adb shell chmod 777 /data/local/tmp
```

#### Error: Ethernet detected but no IP
**Cause:** DHCP client not working
**Fix:** Check DHCP availability (#7) and manually test

---

### 10. **Enable Verbose Logging**
Add debugging output to track execution:

```bash
# Add to service.sh after line 10
echo "DEBUG: Boot completed, starting service..." >> "$LOGFILE"
set -x  # Enable command tracing

# Check updated log
adb shell tail -f /data/local/tmp/ethernet_autoconnect.log
```

---

### 11. **Rebuild Module**
After making changes, rebuild the module:

```bash
# Create new zip file
zip -r ethernet-autoconnect-v1.0.1.zip . -x "*.git*" -x "DEBUGGING.md" -x "*.zip"

# Or on Windows PowerShell:
Compress-Archive -Path install.sh,module.prop,service.sh,uninstall.sh,system -DestinationPath ethernet-autoconnect-v1.0.1.zip -Force
```

---

### 12. **Complete Test Workflow**

1. **Uninstall old module** (via Magisk Manager or `adb shell rm -rf /data/adb/modules/ethernet_autoconnect`)
2. **Convert line endings** on all shell scripts
3. **Create new zip** with updated files
4. **Install via Magisk Manager**
5. **Reboot device**
6. **Check logs** immediately after boot
7. **Plug in ethernet cable**
8. **Monitor logs** for activity
9. **Verify IP assignment** with `ip addr show eth0`

---

## Quick Diagnostic Commands

```bash
# One-liner to check everything
adb shell 'echo "=== Module Status ==="; ls -la /data/adb/modules/ethernet_autoconnect/ 2>&1; echo ""; echo "=== Processes ==="; ps -A | grep -E "service|ethernet" 2>&1; echo ""; echo "=== Interfaces ==="; ip link show 2>&1; echo ""; echo "=== Log ==="; tail -n 20 /data/local/tmp/ethernet_autoconnect.log 2>&1'
```

---

## Still Not Working?

If after following all these steps it's still not working:

1. Share the **complete log file**: `adb shell cat /data/local/tmp/ethernet_autoconnect.log`
2. Share **logcat output**: `adb logcat -d > logcat.txt`
3. Share **interface list**: `adb shell ip link show`
4. Share **process list**: `adb shell ps -A | grep -E "service|ethernet|dhcp"`
5. Provide your **Android version and device model**
