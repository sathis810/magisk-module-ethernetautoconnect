# Ethernet UI Automation Flow

## Complete UI-Only Automation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     SYSTEM BOOT COMPLETE                         │
│              UI Automation Service Started (service.sh)          │
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
                              │              │ DETECT SCREEN RESOLUTION  │
                              │              │ wm size → CENTER_X, CENTER_Y│
                              │              └───────────────────────────┘
                              │                              ↓
                              │              ┌───────────────────────────┐
                              │              │ TIER 1: UIAutomator       │
                              │              │ ─────────────────────     │
                              │              │ • Dump UI hierarchy       │
                              │              │ • Find "ethernet" element │
                              │              │ • Extract bounds coords   │
                              │              │ • Calculate center tap    │
                              │              │ • Execute tap             │
                              │              └───────────────────────────┘
                              │                              ↓
                              │                    ┌─────────┴─────────┐
                              │                    │                   │
                              │              SUCCESS│                   │FAIL
                              │                    ↓                   ↓
                              │            ┌──────────┐    ┌───────────────────┐
                              │            │ Tap Done │    │ TIER 2: Screen    │
                              │            └──────────┘    │ Positioning       │
                              │                    │       │ ─────────────     │
                              │                    │       │ • Scroll to find  │
                              │                    │       │ • Try lower third │
                              │                    │       │ • Try middle      │
                              │                    │       └───────────────────┘
                              │                    │               ↓
                              │                    │       ┌───────┴────────┐
                              │                    │       │                │
                              │                    │ SUCCESS│                │FAIL
                              │                    │       ↓                ↓
                              │                    │  ┌─────────┐  ┌────────────┐
                              │                    │  │Tap Done │  │ TIER 3:    │
                              │                    │  └─────────┘  │ DPAD Nav   │
                              │                    │       │       │ ────────── │
                              │                    │       │       │ • 5x DOWN  │
                              │                    │       │       │ • ENTER    │
                              │                    │       │       └────────────┘
                              │                    │       │               │
                              │                    └───────┴───────────────┘
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
2. **Three-tier intelligent approach**:
   - **Tier 1**: UIAutomator (finds exact coordinates)
   - **Tier 2**: Dynamic screen positioning
   - **Tier 3**: DPAD navigation
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

### Step 1: Open Tethering Settings
```bash
# Try multiple methods to open settings
am start -a android.settings.TETHER_SETTINGS
  ↓ (if fails)
am start -n com.android.settings/.TetherSettings
  ↓ (if fails)
am start -a android.settings.WIRELESS_SETTINGS
```

### Step 2: Detect Screen Resolution
```bash
wm size → Extract Width x Height
Calculate: CENTER_X = Width / 2
Calculate: CENTER_Y = Height / 2
```

### Step 3: UIAutomator Detection (Tier 1)
```bash
1. uiautomator dump /data/local/tmp/ui_dump.xml
2. grep -i "ethernet" ui_dump.xml
3. Extract: bounds="[left,top][right,bottom]"
4. Calculate: TAP_X = (left + right) / 2
5. Calculate: TAP_Y = (top + bottom) / 2
6. Execute: input tap TAP_X TAP_Y
```

**Example Output:**
```
UIAutomator found bounds: [48,789][1032,912]
Found Ethernet toggle at coordinates: 540,850
Tapped Ethernet toggle
```

### Step 4: Screen Positioning (Tier 2 - Fallback)
```bash
1. Scroll down: input swipe CENTER_X 1500 CENTER_X 700
2. Try position 1: TAP_Y = CENTER_Y + (CENTER_Y / 2)
   → input tap CENTER_X TAP_Y
3. Try position 2: input tap CENTER_X CENTER_Y
```

### Step 5: DPAD Navigation (Tier 3 - Last Resort)
```bash
Loop 5 times:
  input keyevent KEYCODE_DPAD_DOWN
  sleep 0.3
input keyevent KEYCODE_ENTER
```

### Step 6: Return Home
```bash
input keyevent KEYCODE_HOME
```

### Step 7: Verify Success
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
2026-01-06 18:30:20 | Attempting to locate Ethernet toggle using UIAutomator...
2026-01-06 18:30:21 | UIAutomator found bounds: [48,789][1032,912]
2026-01-06 18:30:21 | Found Ethernet toggle at coordinates: 540,850
2026-01-06 18:30:21 | Tapped Ethernet toggle
2026-01-06 18:30:23 | UI automation completed, returning to home...
2026-01-06 18:30:24 | UI automation sequence finished
2026-01-06 18:30:29 | ✓ IP address obtained: 192.168.1.100/24
2026-01-06 18:30:29 | ✓ SUCCESS: UI automation enabled Ethernet!
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
- May need coordinate calibration on custom ROMs
- Slightly slower than command-line (2-5 seconds)

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

1. **Boot** → Service starts
2. **Monitor** → Check eth0 every 5 seconds
3. **Detect** → Cable connected + No IP
4. **Automate** → Open settings + Find toggle + Tap
5. **Verify** → Check IP assignment
6. **Retry** → If failed, wait 5 minutes and repeat
7. **Success** → Monitor for disconnection

---

**This is a pure UI automation solution - no command-line methods are used.**
