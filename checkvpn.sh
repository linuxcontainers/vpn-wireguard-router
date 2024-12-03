#!/bin/sh

ping -4 -c4 -I wg0 www.google.com

if [ $? -ge 1 ]; then
        echo "Did not get a response from google, trying to ping yahoo"

        ping -4 -c4 -I wg0 www.yahoo.com

        if [ $? -ge 1 ]; then
                echo "Did not get a response from yahoo, trying to ping bing"

                ping -4 -c4 -I wg0 www.bing.com

                if [ $? -ge 1 ]; then
                        echo "Did not get a response from bing rebooting the machine"
                        echo "RESTART VPN"
#                       sudo reboot
                fi
        fi
fi

exit 0

