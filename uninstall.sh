#!/system/bin/sh
# Ethernet Auto-Connect - Uninstallation Script

# Re-enable WiFi on uninstall (in case it was disabled)
svc wifi enable 2>/dev/null || true

# Clean up log file
rm -f /data/local/tmp/ethernet_autoconnect.log

# Note: System will handle cleanup of module files automatically
