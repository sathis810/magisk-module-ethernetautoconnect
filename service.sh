#!/system/bin/sh

# Wait until system is fully booted
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done

LOGFILE="/data/local/tmp/force_eth.log"

echo "$(date): Ethernet force service started" >> $LOGFILE

while true; do
    if [ -d /sys/class/net/eth0 ]; then
        # Check cable connection (carrier)
        if [ "$(cat /sys/class/net/eth0/carrier 2>/dev/null)" = "1" ]; then
            STATE=$(cat /sys/class/net/eth0/operstate 2>/dev/null)
            if [ "$STATE" != "up" ]; then
                ip link set eth0 up
                echo "$(date): eth0 forced UP" >> $LOGFILE
            fi
        fi
    fi
    sleep 3
done
