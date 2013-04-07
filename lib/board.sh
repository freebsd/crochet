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

# Default is to install world but not
# populate /usr/src and /usr/ports
FREEBSD_INSTALL_WORLD=y
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

    IMG=${WORKDIR}/FreeBSD-${TARGET_ARCH}-${KERNCONF}.img
}

board_default_create_image ( ) {
    disk_create_image $IMG $IMAGE_SIZE
}
strategy_add $PHASE_IMAGE_BUILD_LWW board_default_create_image

# Default is to create a single UFS partition inside an MBR
board_default_partition_image ( ) {
    disk_partition_mbr
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW board_default_partition_image

# Default mounts just the FreeBSD partition
board_default_mount_partitions ( ) {
    disk_ufs_mount ${BOARD_FREEBSD_MOUNTPOINT}
}
strategy_add $PHASE_MOUNT_LWW board_default_mount_partitions

board_installworld ( ) {
    if [ -n "$FREEBSD_INSTALL_WORLD" ]; then
	freebsd_installworld ${BOARD_FREEBSD_MOUNTPOINT}
    fi
}
strategy_add $PHASE_FREEBSD_BASE_INSTALL board_installworld

board_overlay_files ( ) {
    if [ -d ${BOARDDIR}/overlay ]; then
	echo "Overlaying board-specific files from ${BOARDDIR}/overlay"
	(cd ${BOARDDIR}/overlay; find . | cpio -pmud ${BOARD_FREEBSD_MOUNTPOINT})
    fi
}
strategy_add $PHASE_FREEBSD_LATE_CUSTOMIZATION board_overlay_files

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
