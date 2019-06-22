#!/usr/bin/env bash

fhem_log="/opt/fhem/log/fhem.log"

echo -e "\n\n\n\n\n" >> $fhem_log
echo "******************** RELOAD TRIGGERED ********************" >> $fhem_log
date >> $fhem_log
echo -e "\n\n" >> $fhem_log

service fhem restart || {
    echo "Reload failed!"

    echo
    echo " =====> [Journal]"
    journalctl -xe --no-pager

    echo
    echo " =====> [Systemd]"
    systemctl --no-pager status fhem.service

    echo
    echo " =====> [Probing fhem.pl]"
    perl /opt/fhem/fhem.pl /opt/fhem/fhem.cfg

    exit 1
}

echo "Reload done"