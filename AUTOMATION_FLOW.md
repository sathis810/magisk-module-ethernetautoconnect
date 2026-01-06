# Ethernet Auto-Detection & Enabling Flow

## Complete Automation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     SYSTEM BOOT COMPLETE                         │
│                  Service Started (service.sh)                    │
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
                    │         │    │   ✓ OK   │      │ ENABLE NEEDED │
                    │         │    │  Reset   │      │ Attempt < 3?  │
                    │         │    │ Counters │      └───────────────┘
                    │         │    └──────────┘              ↓
                    │         │          ↓           ┌───────┴────────┐
                    │         │          │        YES│                │NO
                    └─────────┴──────────┘           ↓                ↓
                              ↑          ┌───────────────────┐  ┌─────────────┐
                              │          │  COMMAND-LINE     │  │ UI AUTOMATION│
                              │          │  METHODS          │  │  FALLBACK    │
                              │          │  (Tier 1)         │  │  (Tier 2)    │
                              │          └───────────────────┘  └─────────────┘
                              │                  ↓                      ↓
                              │          ┌───────────────────┐         │
                              │          │ 1. cmd connectivity│         │
                              │          │ 2. ndc tether     │         │
                              │          │ 3. ip link set up │         │
                              │          │ 4. dhcpcd request │         │
                              │          └───────────────────┘         │
                              │                  ↓                     │
                              │          ┌───────────────────┐         │
                              │          │  Wait 15 seconds  │         │
                              │          │  (DHCP timeout)   │         │
                              │          └───────────────────┘         │
                              │                  ↓                     │
                              │          ┌───────────────────┐         │
                              │          │ Increment Counter │         │
                              │          │ Attempt++         │         │
                              │          └───────────────────┘         │
                              └──────────────────┬───────────────────────┘
                                                 │
    ┌────────────────────────────────────────────┘
    │
    ↓
┌─────────────────────────────────────────────────────────────────┐
│                     UI AUTOMATION SEQUENCE                       │
└─────────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 1: Open Tethering Settings                                 │
│  ├─ Try: am start -a android.settings.TETHER_SETTINGS           │
│  ├─ Fallback 1: am start -n com.android.settings/.TetherSettings│
│  └─ Fallback 2: am start -a android.settings.WIRELESS_SETTINGS  │
└─────────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 2: Detect Screen Resolution                                │
│  └─ wm size → Calculate CENTER_X, CENTER_Y                      │
└─────────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 3: TIER 1 - UIAutomator Smart Detection                    │
│  ├─ Run: uiautomator dump /data/local/tmp/ui_dump.xml          │
│  ├─ Search: grep -i "ethernet"                                  │
│  ├─ Extract: bounds="[left,top][right,bottom]"                  │
│  ├─ Calculate: TAP_X = (left+right)/2, TAP_Y = (top+bottom)/2  │
│  └─ Execute: input tap TAP_X TAP_Y                              │
└─────────────────────────────────────────────────────────────────┘
    ↓
    │ If UIAutomator fails ↓
    │
┌─────────────────────────────────────────────────────────────────┐
│ STEP 4: TIER 2 - Dynamic Screen Positioning                     │
│  ├─ Scroll: input swipe CENTER_X 1500 CENTER_X 700              │
│  ├─ Try Position 1: CENTER_X, (CENTER_Y + CENTER_Y/2)          │
│  ├─ Try Position 2: CENTER_X, CENTER_Y                          │
│  └─ Wait between attempts                                        │
└─────────────────────────────────────────────────────────────────┘
    ↓
    │ If screen taps fail ↓
    │
┌─────────────────────────────────────────────────────────────────┐
│ STEP 5: TIER 3 - DPAD Navigation                                │
│  ├─ Press KEYCODE_DPAD_DOWN (5 times)                           │
│  └─ Press KEYCODE_ENTER                                          │
└─────────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 6: Return to Home                                           │
│  └─ input keyevent KEYCODE_HOME                                  │
└─────────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 7: Verify IP Assignment                                     │
│  ├─ Wait 5 seconds for DHCP                                      │
│  ├─ Check IP 5 times (2 sec intervals)                          │
│  ├─ If SUCCESS: Log "✓ UI automation successful!"               │
│  └─ If FAIL: Log "✗ UI automation did not result in IP"         │
└─────────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 8: Auto-Retry Logic                                         │
│  ├─ Reset counters                                               │
│  ├─ Wait 30 seconds                                              │
│  └─ If still no IP after 5 minutes, retry entire sequence       │
└─────────────────────────────────────────────────────────────────┘
    ↓
    └──────► RETURN TO CONTINUOUS MONITORING (top)
```

## Key Features

### ✅ **Auto-Detection**
- Continuously monitors `/sys/class/net/eth0` 
- Checks carrier status (cable connected = 1)
- Verifies IP address assignment

### ✅ **Smart Enabling**
1. **Command-line first** (3 attempts, 30s cooldown)
2. **UI automation fallback** (if commands fail)
3. **Three-tier UI approach** (UIAutomator → Screen taps → DPAD)

### ✅ **Self-Healing**
- Resets counters when IP obtained
- Retries UI automation after 5 minutes if failed
- Comprehensive logging at every step

### ✅ **Compatibility**
- Works with Android 14, 15, 16+
- Supports different screen resolutions
- Falls back to multiple methods

## Log Examples

### Successful Command-Line Enable:
```
2026-01-06 14:23:45 | Ethernet connected but no IP → enabling ethernet tethering (attempt 1/3)
2026-01-06 14:23:45 | Enabled Ethernet tethering via connectivity command
2026-01-06 14:23:45 | Added eth0 to tethering via ndc
2026-01-06 14:23:45 | Brought eth0 interface up
2026-01-06 14:23:45 | Requested DHCP for eth0
```

### Successful UI Automation:
```
2026-01-06 14:24:15 | =========================================
2026-01-06 14:24:15 | Max command-line restart attempts reached!
2026-01-06 14:24:15 | Ethernet cable detected but no IP assigned
2026-01-06 14:24:15 | Attempting UI automation as fallback...
2026-01-06 14:24:15 | =========================================
2026-01-06 14:24:15 | Opening Tethering settings UI...
2026-01-06 14:24:15 | Screen center: 540x960
2026-01-06 14:24:18 | Settings opened, waiting for UI to stabilize...
2026-01-06 14:24:20 | Attempting to locate Ethernet toggle using UIAutomator...
2026-01-06 14:24:21 | UIAutomator found bounds: [48,789][1032,912]
2026-01-06 14:24:21 | Found Ethernet toggle at coordinates: 540,850
2026-01-06 14:24:21 | Tapped Ethernet toggle
2026-01-06 14:24:23 | UI automation completed, returning to home...
2026-01-06 14:24:24 | UI automation sequence finished
2026-01-06 14:24:29 | ✓ IP address obtained: 192.168.1.100/24
2026-01-06 14:24:29 | ✓ UI automation successful! Ethernet is now active.
```

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
```

