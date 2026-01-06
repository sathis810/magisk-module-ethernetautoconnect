# Force Ethernet Always On

A Magisk module that automatically enables and maintains Ethernet (eth0) connectivity on Android devices.

## Features

- 🔌 **Auto-Enable Ethernet**: Automatically brings up eth0 interface when an Ethernet cable is connected
- 📡 **Carrier Detection**: Monitors cable connection status using carrier detection
- ♻️ **Auto-Recovery**: Re-enables eth0 every 3 seconds if it gets disabled
- 🎯 **UI Automation**: Automatically opens Tethering settings and clicks to enable Ethernet when command-line methods fail
- 📝 **Logging**: Comprehensive logging to `/data/local/tmp/force_eth.log` for debugging
- 🚀 **Boot Integration**: Starts automatically after system boot completion
- 🛠️ **Multi-Method Approach**: Tries command-line methods first, falls back to UI automation if needed

## Compatibility

- **Android**: 14, 15, 16 (should work on other versions too)
- **Magisk**: 20.4+ (tested on Magisk 30)
- **Requirements**: Device must have Ethernet hardware (eth0 interface)
- **Note**: This module uses the modern Magisk format (no META-INF required)

## Installation

1. Download the module `.zip` file
2. Open Magisk Manager app
3. Go to **Modules** → **Install from storage**
4. Select the downloaded `.zip` file
5. Reboot your device

## How It Works

The module runs a background service that:
1. Waits for system boot completion
2. Continuously monitors the eth0 interface
3. Checks if an Ethernet cable is connected (carrier status) and IP address status
4. Attempts to enable Ethernet using multiple methods:
   - **Command-line methods** (priority):
     - `cmd connectivity tether ethernet on`
     - `ndc tether interface add eth0`
     - Direct interface manipulation with `ip link set eth0 up`
     - DHCP request using `dhcpcd`
   - **UI Automation fallback**:
     - After 3 failed command-line attempts, opens Android Settings
     - Navigates to Tethering settings
     - Simulates tap on Ethernet tethering toggle
5. Repeats monitoring every 5 seconds

## Logs

To view the module logs:

```bash
adb shell
cat /data/local/tmp/force_eth.log
```

Or using a terminal emulator on your device:

```bash
su
cat /data/local/tmp/force_eth.log
```

## Uninstallation

1. Open Magisk Manager
2. Go to **Modules**
3. Find "Force Ethernet Always On"
4. Tap **Remove**
5. Reboot your device

The uninstall script will automatically clean up the log file.

## UI Automation Configuration

The module includes **intelligent UI automation** as a fallback when command-line methods don't work on your Android device.

### How UI Automation Works

When **eth0 is available** but **no IP address is assigned** after 3 command-line attempts, the module automatically:

1. **Opens Tethering Settings** using multiple methods:
   - `am start -a android.settings.TETHER_SETTINGS`
   - Alternative component names for different Android versions
   - Wireless settings as last resort

2. **Locates Ethernet Toggle** using intelligent detection:
   - **Primary**: UIAutomator dumps UI hierarchy to find exact Ethernet toggle coordinates
   - **Fallback 1**: Dynamic screen-resolution-based tap positions
   - **Fallback 2**: DPAD navigation (works on devices with D-pad support)

3. **Verifies Success** by checking if IP address was obtained after automation

4. **Auto-Retry** if unsuccessful (retries after 5 minutes)

### Three-Tier Automation Approach

**Tier 1: UIAutomator (Most Reliable)**
- Dumps UI hierarchy using `uiautomator dump`
- Parses XML to find elements containing "ethernet"
- Extracts exact `bounds` coordinates
- Taps center of the toggle element

**Tier 2: Dynamic Screen Positioning**
- Detects screen resolution automatically
- Calculates tap positions based on common Android UI patterns
- Tries multiple positions (lower third, middle, etc.)
- Includes scroll gestures to ensure toggle is visible

**Tier 3: DPAD Navigation**
- Uses keyboard events (KEYCODE_DPAD_DOWN, KEYCODE_ENTER)
- Works on devices with accessibility services
- Device-agnostic approach

### Testing UI Automation

Before relying on the automated service, test and calibrate the UI automation:

```bash
adb push test_ui_automation.sh /data/local/tmp/
adb shell
su
cd /data/local/tmp
chmod +x test_ui_automation.sh
./test_ui_automation.sh
```

This test script will:
1. Detect your screen resolution
2. Open the Tethering settings
3. Try different tap positions
4. Dump UI hierarchy to find exact Ethernet toggle coordinates
5. Save results to `/data/local/tmp/ethernet_elements.txt`

### Manual Coordinate Detection (If Needed)

For devices where automatic detection fails:

```bash
# Open tethering settings
am start -a android.settings.TETHER_SETTINGS

# Dump UI hierarchy
uiautomator dump /data/local/tmp/window_dump.xml

# Search for Ethernet toggle
grep -i ethernet /data/local/tmp/window_dump.xml
```

Output example:
```xml
<node text="Ethernet tethering" bounds="[48,789][1032,912]" .../>
```

Calculate center: X = (48 + 1032) / 2 = 540, Y = (789 + 912) / 2 = 850

### Monitoring Automation Success

Check logs to see if UI automation worked:

```bash
tail -f /data/local/tmp/force_eth.log
```

Look for:
- `✓ UI automation successful!` - Toggle was clicked and IP obtained
- `✗ UI automation did not result in IP assignment` - Toggle may not have been found
- `Found Ethernet toggle at coordinates: X,Y` - UIAutomator successfully located toggle

## Troubleshooting

### Ethernet not enabling

1. Check if your device has eth0 interface:
   ```bash
   ls /sys/class/net/
   ```

2. Check if cable is connected:
   ```bash
   cat /sys/class/net/eth0/carrier
   ```
   (Should return `1` if cable is connected)

3. Check module logs:
   ```bash
   cat /data/local/tmp/force_eth.log
   ```

### Service not starting

1. Verify the module is enabled in Magisk Manager
2. Check Magisk logs in the app
3. Ensure you rebooted after installation

### UI Automation not working

1. **Screen coordinates mismatch**: Run `test_ui_automation.sh` to find correct coordinates for your device
2. **Different Settings UI**: Your device may use a different Settings layout. Try these commands to find the right activity:
   ```bash
   # List all Settings activities
   pm list packages -f | grep settings
   
   # Try alternative ways to open tethering
   am start -a android.intent.action.MAIN -n com.android.settings/.TetherSettings
   am start -a android.settings.NETWORK_SETTINGS
   ```
3. **Check logs**: The module logs all UI automation attempts:
   ```bash
   cat /data/local/tmp/force_eth.log | grep -i "UI automation"
   ```

### Ethernet works briefly then stops

This might indicate the command-line methods are working initially but failing later. The module will automatically attempt UI automation after 3 failed attempts.

## Technical Details

- **ID**: `force-ethernet-always-on`
- **Service Script**: Runs in background checking eth0 status
- **Check Interval**: 3 seconds
- **Log Location**: `/data/local/tmp/force_eth.log`

## Contributing

Feel free to submit issues or pull requests on the GitHub repository.

## Author

**sathis810**

## License

This module is provided as-is without any warranty. Use at your own risk.

## Changelog

### v2.0 (UI Automation Update)
- ✨ Added UI automation fallback when command-line methods fail
- 🎯 Automatic navigation to Tethering settings and toggle click
- 🧪 Included test script for coordinate calibration
- 📊 Enhanced logging with IP address monitoring
- 🔄 Retry logic with cooldown periods (30 seconds between attempts)
- ⚡ Multiple command-line methods attempted before UI fallback
- 🛡️ Max retry limits to prevent excessive system load
- 📱 Dynamic screen resolution detection for tap coordinates

### v1.0 (Initial Release)
- Auto-enable eth0 on cable connection
- Carrier detection support
- 3-second monitoring interval
- Logging functionality
- Clean uninstall process
