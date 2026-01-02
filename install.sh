#!/system/bin/sh
# Ethernet Auto-Connect - Installation Script

# Magisk Module Template: https://github.com/topjohnwu/magisk-module-template

SKIPUNZIP=0

# Print installation messages
ui_print "**************************************"
ui_print " Ethernet Auto-Connect Module"
ui_print "**************************************"
ui_print ""
ui_print "Installing ethernet auto-connect module..."
ui_print ""
ui_print "Features:"
ui_print "- Auto-enables eth0/eth1 when connected"
ui_print "- Disables WiFi during ethernet use"
ui_print "- Restores WiFi when ethernet disconnects"
ui_print "- DHCP configuration"
ui_print ""
ui_print "Target: Android 14, 15, 16"
ui_print ""

# Set permissions
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm $MODPATH/service.sh 0 0 0755
set_perm $MODPATH/system/bin/ethernet_manager 0 0 0755

ui_print "Installation complete!"
ui_print "Please reboot your device."
ui_print ""
ui_print "Logs: /data/local/tmp/ethernet_autoconnect.log"
ui_print "**************************************"
