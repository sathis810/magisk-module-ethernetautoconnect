# Ethernet UI Automation Flow

## Complete UI-Only Automation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     SYSTEM BOOT COMPLETE                         │
│              UI Automation Service Started (service.sh)          │
│              + 10 Second Wait for System Stabilization           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                     CONTINUOUS MONITORING                        │
│                    (Every 5 seconds loop)                        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                    ┌─────────────────┐
                    │  Check eth0     │
                    │  Interface      │
                    │  Available?     │
                    └─────────────────┘
                              ↓
                    ┌─────────┴─────────┐
                    │                   │
                 NO │                   │ YES
                    ↓                   ↓
              ┌─────────┐        ┌──────────────┐
              │  WAIT   │        │ Check Carrier│
              │ 3 sec   │        │ (Cable OK?)  │
              └─────────┘        └──────────────┘
                    ↓                   ↓
                    │         ┌─────────┴──────────┐
                    │         │                    │
                    │      NO │                    │ YES
                    │         ↓                    ↓
                    │   ┌─────────┐         ┌─────────────┐
                    │   │  WAIT   │         │  Check IP   │
                    │   │ 5 sec   │         │  Assigned?  │
                    │   └─────────┘         └─────────────┘
                    │         ↓                    ↓
                    │         │          ┌─────────┴─────────┐
                    │         │          │                   │
                    │         │       YES│                   │NO
                    │         │          ↓                   ↓
                    │         │    ┌──────────┐      ┌───────────────┐
                    │         │    │   ✓ OK   │      │ UI AUTOMATION │
                    │         │    │  Reset   │      │   TRIGGERED   │
                    │         │    │   Flag   │      └───────────────┘
                    │         │    └──────────┘              ↓
                    │         │          ↓                   │
                    └─────────┴──────────┘                   │
                              ↑                              │
                              │                              │
                              │                              ↓
                              │              ┌───────────────────────────┐
                              │              │ OPEN TETHERING SETTINGS   │
                              │              └───────────────────────────┘
                              │                              ↓
                              │              ┌───────────────────────────┐
                              │              │ TAP ETHERNET TOGGLE       │
                              │              │ Hardcoded: X=610, Y=1810  │
                              │              │ input tap 610 1810        │
                              │              └───────────────────────────┘
                              │                              ↓
                              │              ┌───────────────────────────┐
                              │              │ RETURN TO HOME SCREEN     │
                              │              │ input keyevent KEYCODE_HOME│
                              │              └───────────────────────────┘
                              │                              ↓
                              │              ┌───────────────────────────┐
                              │              │ VERIFY IP ASSIGNMENT      │
                              │              │ ─────────────────────     │
                              │              │ • Wait 5 seconds for DHCP│
                              │              │ • Check IP 5 times       │
                              │              │ • 2 second intervals     │
                              │              └───────────────────────────┘
                              │                              ↓
                              │                    ┌─────────┴─────────┐
                              │                    │                   │
                              │            SUCCESS │                   │ FAIL
                              │                    ↓                   ↓
                              │        ┌───────────────────┐  ┌────────────────┐
                              │        │ ✓ Log Success     │  │ ✗ Log Failure  │
                              │        │ Set Flag          │  │ Set Flag       │
                              │        │ Return to Monitor │  │ Wait 5 minutes │
                              │        └───────────────────┘  │ Reset & Retry  │
                              │                    │          └────────────────┘
                              │                    │                   │
                              └────────────────────┴───────────────────┘
```

## Key Features - UI Automation Only

### ✅ **Auto-Detection**
- Continuously monitors `/sys/class/net/eth0` 
- Checks carrier status (cable connected = 1)
- Verifies IP address assignment

### ✅ **UI Automation Flow**
1. **Immediate trigger** when eth0 detected without IP
2. **Direct tap approach**:
   - Hardcoded coordinates (X=610, Y=1810)
   - Fast and reliable - no detection needed
   - Device-specific calibration
3. **Automatic verification** of IP assignment

### ✅ **Self-Healing**
- Resets flag when IP obtained
- Retries after 5 minutes if failed
- 10-second cooldown between attempts

### ✅ **Pure UI Automation**
- ❌ No command-line methods
- ✅ Direct UI interaction only
- ✅ Works on locked-down Android systems

## Detailed UI Automation Steps

### Step 1: Wait for Boot Completion
```bash
# Wait for system property
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done

# Additional 10-second wait for system services
sleep 10
```

### Step 2: Open Tethering Settings
```bash
# Try multiple methods to open settings
am start -a android.settings.TETHER_SETTINGS
  ↓ (if fails)
am start -n com.android.settings/.TetherSettings
  ↓ (if fails)
am start -a android.settings.WIRELESS_SETTINGS
```

### Step 3: Wait for UI Stabilization
```bash
sleep 2  # Let the UI fully load
```

### Step 4: Tap Ethernet Toggle (Hardcoded)
```bash
# Direct tap at calibrated coordinates
input tap 610 1810
sleep 2
```

**Example Output:**
```
Tapping Ethernet toggle at hardcoded coordinates: 610,1810
Tapped Ethernet toggle
```

### Step 5: Return Home
```bash
input keyevent KEYCODE_HOME
```

### Step 6: Verify Success
```bash
Wait 5 seconds
Loop 5 times:
  Check: ip -4 addr show eth0 | grep "inet"
  If IP found: ✓ SUCCESS
  sleep 2 seconds
If no IP after 5 attempts: ✗ FAIL
```

## Log Examples

### Successful UI Automation:
```
2026-01-06 18:30:00 | Waiting for boot completion...
2026-01-06 18:30:02 | Boot completed
2026-01-06 18:30:02 | Waiting 10 seconds for system services to stabilize...
2026-01-06 18:30:12 | =========================================
2026-01-06 18:30:12 | Force Ethernet UI Automation Service Started
2026-01-06 18:30:12 | Interface: eth0
2026-01-06 18:30:12 | Mode: UI AUTOMATION ONLY
2026-01-06 18:30:12 | =========================================
2026-01-06 18:30:15 | =========================================
2026-01-06 18:30:15 | TRIGGER: Ethernet cable detected but no IP
2026-01-06 18:30:15 | Starting UI automation sequence...
2026-01-06 18:30:15 | =========================================
2026-01-06 18:30:15 | Opening Tethering settings UI...
2026-01-06 18:30:15 | Screen center: 540x960
2026-01-06 18:30:18 | Settings opened, waiting for UI to stabilize...
2026-01-06 18:30:20 | Tapping Ethernet toggle at hardcoded coordinates: 610,1810
2026-01-06 18:30:20 | Tapped Ethernet toggle
2026-01-06 18:30:22 | UI automation completed, returning to home...
2026-01-06 18:30:23 | UI automation sequence finished
2026-01-06 18:30:28 | ✓ IP address obtained: 192.168.1.100/24
2026-01-06 18:30:28 | ✓ SUCCESS: UI automation enabled Ethernet!
```

### Retry After Failure:
```
2026-01-06 18:31:00 | ✗ FAILED: No IP assignment after UI automation
2026-01-06 18:31:00 | Possible causes:
2026-01-06 18:31:00 |   → Toggle not found/clicked correctly
2026-01-06 18:31:00 |   → DHCP server not responding on network
2026-01-06 18:31:00 |   → Manual settings configuration required
2026-01-06 18:36:00 | Auto-retry: Resetting automation flag after 5-minute wait...
2026-01-06 18:36:10 | =========================================
2026-01-06 18:36:10 | TRIGGER: Ethernet cable detected but no IP
2026-01-06 18:36:10 | Starting UI automation sequence...
```

## Why UI-Only Mode?

### ✅ Advantages:
- **Universal compatibility**: Works on any Android device with UI
- **No permission issues**: Doesn't require special system permissions
- **Works on locked-down systems**: Command-line methods often blocked
- **Visual verification**: User can see what's happening
- **Consistent across Android versions**: UI is more stable than CLI APIs

### ⚠️ Considerations:
- Requires screen to be unlocked (on first boot)
- **Uses hardcoded coordinates (610, 1810)** - may need adjustment for different devices/resolutions
- Slightly slower than command-line (2-5 seconds)
- 10-second boot delay ensures system stability

## Testing Commands

```bash
# Check if eth0 exists
ls -la /sys/class/net/eth0

# Check carrier status
cat /sys/class/net/eth0/carrier

# Check IP address
ip -4 addr show eth0

# View live logs
tail -f /data/local/tmp/force_eth.log

# Test UI automation manually
sh /data/local/tmp/test_ui_automation.sh

# Validate device compatibility
sh /data/local/tmp/validate_automation.sh
```

## Flowchart Summary

1. **Boot** → Wait for completion + 10 second stabilization
2. **Service Start** → Initialize monitoring loop
3. **Monitor** → Check eth0 every 5 seconds
4. **Detect** → Cable connected + No IP
5. **Automate** → Open settings + Tap at 610,1810
6. **Verify** → Check IP assignment
7. **Retry** → If failed, wait 5 minutes and repeat
8. **Success** → Monitor for disconnection

---

## Configuration Notes

### Hardcoded Coordinates
The script uses hardcoded tap coordinates **X=610, Y=1810** for the Ethernet toggle switch. These coordinates are device-specific and may need adjustment if:
- Using a different screen resolution
- Using a custom ROM with modified UI layout
- The Settings app layout changes after an update

To find the correct coordinates for your device:
1. Enable Developer Options → "Pointer location"
2. Open Tethering settings
3. Touch the Ethernet toggle and note the X,Y coordinates
4. Update `TAP_X` and `TAP_Y` values in `service.sh`

### Boot Wait Period
A 10-second wait after boot completion ensures:
- All Android system services are fully initialized
- UI automation tools are ready
- Settings app can be launched reliably
- Reduces race conditions during startup

---

**This is a pure UI automation solution - no command-line methods are used.**
