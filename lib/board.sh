#
# Default implementations of board routines.
#

# Boards that need more than this can define their own.
BOARD_FREEBSD_MOUNTPOINT=${WORKDIR}/_.mount.freebsd
BOARD_BOOT_MOUNTPOINT=${WORKDIR}/_.mount.boot

# Default is to install world ...
FREEBSD_INSTALL_WORLD=y

# List of all board dirs.
BOARDDIRS=""

# $1: name of board directory
#
board_setup ( ) {
    BOARDDIR=${TOPDIR}/board/$1
    if [ ! -e ${BOARDDIR}/setup.sh ]; then
        echo "Can't setup board $1."
        echo "No setup.sh in ${BOARDDIR}."
        exit 1
    fi
    BOARDDIRS="$BOARDDIRS $BOARDDIR"
    echo "Board: $1"
    . $BOARDDIR/setup.sh

    PRIORITY=20 strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_overlay_files $BOARDDIR
    BOARDDIR=
}

board_generate_image_name ( ) {
    if [ -z "${IMG}" ]; then
        if [ -z "${SOURCE_VERSION}" ]; then
           IMG=${WORKDIR}/FreeBSD-${TARGET_ARCH}-${OS_VERSION}-${KERNCONF}.img
       else
           IMG=${WORKDIR}/FreeBSD-${TARGET_ARCH}-${OS_VERSION}-${KERNCONF}-r${SOURCE_VERSION}.img
       fi
    fi
    echo "Image name is:"
    echo "    ${IMG}"
}
# Run this late, so we print image name after other post-config has had a chance
PRIORITY=200 strategy_add $PHASE_POST_CONFIG board_generate_image_name


# $1 - BOARDDIR
# Registered from end of board_setup so that it can get the BOARDDIR
# as an argument.  (There are rare cases where we actually load
# more than one board definition; in those cases this will get
# registered and run once for each BOARDDIR.)
# TODO: Are there other examples of this kind of thing?
# If so, is there a better mechanism?
board_overlay_files ( ) {
    if [ -d $1/overlay ]; then
        echo "Overlaying board-specific files from $1/overlay"
        (cd $1/overlay; find . | cpio -pmud ${BOARD_FREEBSD_MOUNTPOINT})
    fi
}

board_defined ( ) {
    if [ -z "$BOARDDIRS" ]; then
        echo "No board setup?"
        echo "Make sure a suitable board_setup command appears at the top of ${CONFIGFILE}"
        exit 1
    fi
}
strategy_add $PHASE_POST_CONFIG board_defined

# TODO: Not every board requires -CURRENT; copy this into all the
# board setups and remove it from here.
strategy_add $PHASE_CHECK freebsd_current_test

board_check_image_size_set ( ) {
    # Check that IMAGE_SIZE is set.
    # For now, support SD_SIZE for backwards compatibility.
    # June 2013: Remove SD_SIZE support entirely.
    if [ -z "${IMAGE_SIZE}" ]; then
        if [ -z "${SD_SIZE}" ]; then
            echo "Error: \$IMAGE_SIZE not set."
            exit 1
        fi
        echo "SD_SIZE is deprecated; please use IMAGE_SIZE instead"
        IMAGE_SIZE=${SD_SIZE}
    fi
}
strategy_add $PHASE_CHECK board_check_image_size_set

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

board_default_buildworld ( ) {
    freebsd_buildworld
}
strategy_add $PHASE_BUILD_WORLD board_default_buildworld

board_default_buildkernel ( ) {
    freebsd_buildkernel
}
strategy_add $PHASE_BUILD_KERNEL board_default_buildkernel

board_default_installworld ( ) {
    if [ -n "$FREEBSD_INSTALL_WORLD" ]; then
        freebsd_installworld ${BOARD_FREEBSD_MOUNTPOINT}
    fi
}
strategy_add $PHASE_FREEBSD_INSTALLWORLD_LWW board_default_installworld

board_default_goodbye ( ) {
    echo "DONE."
    echo "Completed disk image is in: ${IMG}"
    echo
    echo "Copy to a suitable memory card using a command such as:"
    echo "dd if=${IMG} of=/dev/da0 bs=1m"
    echo "(Replace /dev/da0 with the appropriate path for your card reader.)"
    echo
}
strategy_add $PHASE_GOODBYE_LWW board_default_goodbye
