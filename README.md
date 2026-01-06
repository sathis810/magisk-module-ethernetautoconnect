# Force Ethernet Always On

A Magisk module that automatically enables and maintains Ethernet (eth0) connectivity on Android devices.

## Features

- 🔌 **Auto-Enable Ethernet**: Automatically brings up eth0 interface when an Ethernet cable is connected
- 📡 **Carrier Detection**: Monitors cable connection status using carrier detection
- ♻️ **Auto-Recovery**: Re-enables eth0 every 3 seconds if it gets disabled
- 📝 **Logging**: Comprehensive logging to `/data/local/tmp/force_eth.log` for debugging
- 🚀 **Boot Integration**: Starts automatically after system boot completion

## Compatibility

- **Android**: 14, 15, 16 (should work on other versions too)
- **Magisk**: 20.4+ (recommended latest version)
- **Requirements**: Device must have Ethernet hardware (eth0 interface)

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
3. Checks if an Ethernet cable is connected (carrier status)
4. If cable is connected but interface is down, brings it up
5. Repeats check every 3 seconds

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

### v1.0 (Initial Release)
- Auto-enable eth0 on cable connection
- Carrier detection support
- 3-second monitoring interval
- Logging functionality
- Clean uninstall process
