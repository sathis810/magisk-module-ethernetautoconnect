# Ethernet Auto-Connect - Magisk Module

Automatically enables ethernet (eth0/eth1) when connected, disables WiFi during ethernet use, and restores WiFi when ethernet disconnects.

## Features

- ✅ Auto-detects and enables ethernet interfaces (eth0, eth1)
- ✅ Automatic DHCP configuration with multiple fallback methods
- ✅ Disables WiFi when ethernet is active
- ✅ Re-enables WiFi when ethernet cable is unplugged
- ✅ Real-time monitoring with 3-second refresh rate
- ✅ Comprehensive logging for troubleshooting
- ✅ Supports Android 14, 15, and 16

## Requirements

- Magisk v20.4 or higher
- Android 14, 15, or 16
- Ethernet adapter (USB or built-in) with eth0 or eth1 interface name
- Root access via Magisk

## Installation

1. Download the module ZIP file
2. Open Magisk Manager app
3. Tap **Modules** tab
4. Tap **Install from storage**
5. Select the downloaded ZIP file
6. Wait for installation to complete
7. **Reboot your device**

## How It Works

The module runs a background service that continuously monitors ethernet connection status:

1. **Connection Detected**: When ethernet cable is plugged in:
   - Brings up eth0/eth1 interface
   - Requests IP address via DHCP
   - Disables WiFi automatically

2. **Disconnection Detected**: When ethernet cable is unplugged:
   - Brings down ethernet interface
   - Re-enables WiFi automatically

## Troubleshooting

### Check Logs

View detailed logs to diagnose issues:
```bash
adb shell cat /data/local/tmp/ethernet_autoconnect.log
```

Or on device (requires terminal emulator):
```bash
su
cat /data/local/tmp/ethernet_autoconnect.log
```

### Common Issues

**Ethernet not enabling:**
- Verify your ethernet adapter is recognized: `ifconfig` or `ip addr`
- Check if interface is named eth0 or eth1
- Review logs for DHCP errors

**WiFi not disabling/enabling:**
- Ensure `svc wifi` commands work: `svc wifi disable` / `svc wifi enable`
- Some custom ROMs may require additional permissions

**No IP address assigned:**
- Check DHCP server on your network
- Try different DHCP client methods (module tries multiple automatically)
- Verify ethernet cable and router connection

### Manual Testing

Test ethernet manager manually:
```bash
su
# Check status
/system/bin/ethernet_manager check

# Manually enable ethernet
/system/bin/ethernet_manager enable eth0

# Manually disable and restore WiFi
/system/bin/ethernet_manager disable eth0
```

## Uninstallation

1. Open Magisk Manager
2. Go to **Modules**
3. Tap **Remove** on "Ethernet Auto-Connect"
4. Reboot device

WiFi will be automatically re-enabled during uninstallation.

## Technical Details

**Ethernet Detection**: Monitors `/sys/class/net/eth*/carrier` for connection state

**DHCP Methods** (in order of attempt):
1. `dhcpcd` - Standard Linux DHCP client
2. `dhcptool` - Samsung and OEM tools
3. `netcfg` - Legacy Android
4. ConnectivityService - Android framework

**WiFi Control**: Uses `svc wifi` service commands (Android 14-16 compatible)

**Monitoring Interval**: 3 seconds for responsive detection

## Log Rotation

Logs are automatically rotated when they exceed 100KB to prevent storage issues.

## Credits

- Author: sathis810
- Version: 1.0.0
- Repository: [magisk-module-ethernetautoconnect](https://github.com/sathis810/magisk-module-ethernetautoconnect)

## License

This module is provided as-is for personal use. Modify and distribute freely.

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review logs at `/data/local/tmp/ethernet_autoconnect.log`
3. Open an issue on GitHub with log details
