#!/system/bin/sh
# Ethernet Auto-Connect - Installation Script

# Magisk Module Template: https://github.com/topjohnwu/magisk-module-template

SKIPUNZIP=0

# Print installation messages
ui_print "**************************************"
ui_print " Force Ethernet Always On"
ui_print "**************************************"
ui_print ""
ui_print "Installing ethernet force module..."
ui_print ""
ui_print "Features:"
ui_print "- Keeps eth0 interface always UP"
ui_print "- Monitors cable connection (carrier)"
ui_print "- Re-enables eth0 every 3 seconds if down"
ui_print ""
ui_print "Target: Android 14, 15, 16"
ui_print ""

# Set permissions
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm $MODPATH/service.sh 0 0 0755
set_perm $MODPATH/uninstall.sh 0 0 0755

ui_print "Installation complete!"
ui_print "Please reboot your device."
ui_print ""
ui_print "Logs: /data/local/tmp/force_eth.log"
ui_print "**************************************"
