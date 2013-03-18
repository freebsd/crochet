#
# Default implementations of board routines.
#
# Most of these are just empty so that boards that don't need
# a separate boot partition, for example, can just omit those routines.
#
# A few of the routines below are "generic_board" routines that
# a lot of boards will want to call.
#

# Boards that need more than this can define their own.
BOARD_FREEBSD_MOUNTPOINT=${WORKDIR}/_.mount.freebsd
BOARD_BOOT_MOUNTPOINT=${WORKDIR}/_.mount.boot

# Default is to install both kernel and WORLD but not
# populate /usr/src and /usr/ports
FREEBSD_INSTALL_WORLD=y
FREEBSD_INSTALL_KERNEL=y
FREEBSD_INSTALL_USR_SRC=
FREEBSD_INSTALL_USR_PORTS=

# $1: name of board directory
#
board_setup ( ) {
    BOARDDIR=${TOPDIR}/board/$1
    if [ ! -e ${BOARDDIR}/setup.sh ]; then
	echo "Can't setup board $1."
	echo "No setup.sh in ${BOARDDIR}."
	exit 1
    fi
    . $BOARDDIR/setup.sh

    echo "Imported board setup for $1"

    IMG=${WORKDIR}/FreeBSD-${KERNCONF}.img
}

board_check_prerequisites ( ) {
    freebsd_current_test
}

board_build_bootloader ( ) { }

# $1 - name of image file
# $2 - SD size from user config.sh
board_create_image ( ) {
    disk_create_image $1 $2
}

# Default is to create a single UFS partition inside an MBR
board_partition_image ( ) {
    disk_partition_mbr
    disk_ufs_create
}

# Default mounts just the FreeBSD partition
board_mount_partitions ( ) {
    disk_ufs_mount ${BOARD_FREEBSD_MOUNTPOINT}
}

# Default board setup doesn't use a separate boot partition
board_populate_boot_partition ( ) {
}

generic_board_populate_freebsd_partition ( ) {
    freebsd_installkernel ${BOARD_FREEBSD_MOUNTPOINT}
    if [ -n "$FREEBSD_INSTALL_WORLD" ]; then
	freebsd_installworld ${BOARD_FREEBSD_MOUNTPOINT}
    fi
    if [ -n "$FREEBSD_INSTALL_USR_SRC" ]; then
	freebsd_install_usr_src ${BOARD_FREEBSD_MOUNTPOINT}
    fi
    if [ -n "$FREEBSD_INSTALL_USR_PORTS" ]; then
	freebsd_install_usr_ports ${BOARD_FREEBSD_MOUNTPOINT}
    fi
    # TODO: Install packages here ?  Or leave that for user customization?
    if [ -d ${BOARDDIR}/overlay ]
    then
	echo "Overlaying board-specific files from ${BOARDDIR}/overlay"
	(cd ${BOARDDIR}/overlay; find . | cpio -pmud ${BOARD_FREEBSD_MOUNTPOINT})
    fi
    if [ -d ${WORKDIR}/overlay ]
    then
	echo "Overlaying files from ${WORKDIR}/overlay"
	(cd ${WORKDIR}/overlay; find . | cpio -pmud ${BOARD_FREEBSD_MOUNTPOINT})
    fi
}

# Many board definitions will override this with a routine that calls
# generic_board_populate_freebsd_partition and then copies/tweaks a
# few board-specific items.
board_populate_freebsd_partition ( ) {
    generic_board_populate_freebsd_partition
}

generic_board_show_message ( ) {
    echo "DONE."
    echo "Completed disk image is in: ${IMG}"
    echo
    echo "Copy to a MicroSDHC card using a command such as:"
    echo "dd if=${IMG} of=/dev/da0 bs=1m"
    echo "(Replace /dev/da0 with the appropriate path for your SDHC card reader.)"
    echo
}

board_show_message ( ) {
    generic_board_show_message
}

board_post_unmount ( ) {
}
