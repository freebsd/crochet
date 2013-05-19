#!/bin/sh
GUESTID=0
/usr/sbin/bhyvectl --destroy --vm=guest$GUESTID > /dev/null 2>&1
