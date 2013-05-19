#!/bin/sh

GUESTID=0
NUMCPUS=2
GUESTRAM=512

echo ""
echo "Available network interfaces:"
echo ""
ifconfig -l

echo ""
echo "Enter the active network device used for bridged networking: i.e. \"em0\""

read BRIDGENIC

echo "Preparing bridged networking"
ifconfig tap$GUESTID down

echo "Okay if you get the error \"does not exist\""
ifconfig tap$GUESTID destroy

echo "Okay if you get the error \"does not exist\""
ifconfig tap$GUESTID create

echo "May report that File exists"
ifconfig bridge0 addm tap$GUESTID addm $BRIDGENIC up
ifconfig tap$GUESTID up

echo "Destroying the guest if already running"
/usr/sbin/bhyvectl --destroy --vm=guest$GUESTID > /dev/null 2>&1

echo "Loading the guest kernel with /usr/sbin/bhyveload"
/usr/sbin/bhyveload -m $GUESTRAM -d $1 guest$GUESTID

echo "Booting the guest kernel with /usr/sbin/bhyve"
echo "FreeBSD 8.* guests may exhibit a few second delay"
/usr/sbin/bhyve -c $NUMCPUS -m $GUESTRAM -AI -H -P -g 0 \
	-s 0:0,hostbridge \
	-s 1:0,virtio-net,tap$GUESTID \
	-s 2:0,virtio-blk,$1 \
	-S 31,uart,stdio \
	guest$GUESTID
