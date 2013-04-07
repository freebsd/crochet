# Add an rc.d script to check the disk size on boot and
# invoke growfs to enlarge the disk.
#
# This allows a single small image to be copied onto
# larger media and automatically be expanded to the full
# size on first boot.
#
# TODO: Track down a GEOM bug that causes resized partitions
# to not always be immediately visible.  This bug prevents
# resizing nested partitions without an intermediate reboot.
# (So a typical MBR slice with a UFS parition in it won't
# be correctly resized until after the second boot.)
#

option_autosize_install ( ) {
    cp ${OPTIONDIR}/autosize etc/rc.d/autosize
    cat >>etc/rc.conf <<EOF
# On first boot, enlarge the root filesystem to fill the SD card
autosize_enable="YES"
EOF
}

# Register the function to run after installworld.
strategy_add $PHASE_FREEBSD_EXTRA_INSTALL option_autosize_install
