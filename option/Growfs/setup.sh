# Add an rc.d script to check the disk size on boot and
# invoke growfs to enlarge the disk.
#
# This allows a single small image to be copied onto
# larger media and automatically be expanded to the full
# size on first boot.
#

option_growfs_install ( ) {
    cat >>etc/rc.conf <<EOF
# On first boot, enlarge the root filesystem to fill the SD card
growfs_enable="YES"
EOF
}
strategy_add $PHASE_FREEBSD_OPTION_INSTALL option_growfs_install
