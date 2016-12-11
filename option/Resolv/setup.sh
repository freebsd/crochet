# Temporary use /etc/resolv.conf for internet connection
# Required by pkg
#
# Usage:
#  option Resolv

copy_resolv_conf ( ) {
    echo "Copying host's resolv.conf"
	cp /etc/resolv.conf ${BOARD_FREEBSD_MOUNTPOINT}/etc/resolv.conf
}
# Ensure it happens before PackageInit (Prio 50)
PRIORITY=40 strategy_add $PHASE_FREEBSD_OPTION_INSTALL copy_resolv_conf

delete_resolv_conf ( ) {
    echo "Deleting resolv.conf"
	rm ${BOARD_FREEBSD_MOUNTPOINT}/etc/resolv.conf
}
# Ensure it happens after Package (Prio 100)
PRIORITY=150 strategy_add $PHASE_FREEBSD_OPTION_INSTALL delete_resolv_conf
