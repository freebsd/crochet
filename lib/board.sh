#
# Default implementations of board routines.
#

# Boards that need more than this can define their own.
board_mountpoint_defaults ( ) {
    if [ -z "${BOARD_UFS_MOUNTPOINT_PREFIX}" ]; then
        BOARD_UFS_MOUNTPOINT_PREFIX=${WORKDIR}/_.mount.ufs
    fi
    if [ -z "${BOARD_FREEBSD_MOUNTPOINT_PREFIX}" ]; then
        BOARD_FREEBSD_MOUNTPOINT_PREFIX=${WORKDIR}/_.mount.freebsd
    fi
    if [ -z "${BOARD_FAT_MOUNTPOINT_PREFIX}" ]; then
        BOARD_FAT_MOUNTPOINT_PREFIX=${WORKDIR}/_.mount.fat
    fi
    if [ -z "${BOARD_BOOT_MOUNTPOINT_PREFIX}" ]; then
        BOARD_BOOT_MOUNTPOINT_PREFIX=${WORKDIR}/_.mount.boot
    fi
}
strategy_add $PHASE_POST_CONFIG board_mountpoint_defaults


# Default is to install world ...
FREEBSD_INSTALL_WORLD=y

# List of all board dirs.
BOARDDIRS=""

# the board's name, later to be used in IMGNAMe
BOARDNAME=""

# $1: name of board directory
#
board_setup ( ) {
    BOARDDIR=${TOPDIR}/board/$1
    BOARDNAME=$1
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
    if [ -z "${IMGDIR}" ]; then
	_IMGDIR=${WORKDIR}
    else
	_IMGDIR=${IMGDIR}
    fi
    if [ ! -z "${IMGNAME}" ]; then
	eval IMG=${_IMGDIR}/${IMGNAME}
    fi
    if [ -z "${IMG}" ]; then
        if [ -z "${SOURCE_VERSION}" ]; then
           IMG=${_IMGDIR}/FreeBSD-${TARGET_ARCH}-${FREEBSD_MAJOR_VERSION}-${KERNCONF}-${BOARDNAME}.img
	else
           IMG=${_IMGDIR}/FreeBSD-${TARGET_ARCH}-${FREEBSD_VERSION}-${KERNCONF}-${SOURCE_VERSION}-${BOARDNAME}.img
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
    if [ -z "${IMAGE_SIZE}" ]; then
        echo "Error: \$IMAGE_SIZE not set."
        exit 1
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

# Default mounts all the FreeBSD partitions
board_default_mount_partitions ( ) {
    board_mount_all
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

board_default_installkernel ( ) {
    freebsd_installkernel "$@"
}
# Note: we don't automatically put installkernel into the
# strategy here because different boards install the kernel
# into different places (e.g., separate firmware or
# separate partition).


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


# $1: absolute index of partition
board_is_boot_partition ( ) {
    local ABSINDEX=$1
    
    if [ "`disk_get_var ${ABSINDEX} BOOT`" = "y" ]; then
	return 0
    else
	return 1
    fi
}

# $1: absolute index of partition
board_is_freebsd_partition ( ) {
    local ABSINDEX=$1
    
    if [ "`disk_get_var ${ABSINDEX} FREEBSD`" = "y" ]; then
	return 0
    else
	return 1
    fi
}


# Wrapper for user-supplied partition customization handlers
#
# $1: absolute index of partition to customize
# $2: name of customization handler
# $3..: any user-supplied handler args
_board_customize_partition ( ) {
    local ABSINDEX=$1
    local CUSTOMIZATION_HANDLER=$2

    BOARD_CURRENT_MOUNTPOINT=`board_mountpoint ${ABSINDEX}`
    cd ${BOARD_CURRENT_MOUNTPOINT}
    eval $CUSTOMIZATION_HANDLER ${ABSINDEX} "$@"
}


#
# The first UFS partition always gets a FreeBSD installation.  This
# routine is used to mark additional UFS partitions for FreeBSD
# installation. It is not necessary, and harmless, to invoke it for
# the first UFS partition.
#
# $1: absolute index of the partition
board_mark_partition_for_freebsd_install ( ) {
    local ABSINDEX=$1

    if ! board_is_freebsd_partition ${ABSINDEX}; then
	disk_set_var ${ABSINDEX} FREEBSD "y"
	
	strategy_add $PHASE_REPLICATE_FREEBSD freebsd_replicate `board_ufs_mountpoint 1` `board_mountpoint ${ABSINDEX}`
    fi
}

#
# Register a handler to be called as the final step in preparing the
# given partition.  The handler is passed the absolute index of the
# partition and any additional arguments that were given at
# registration time. When the handler is called, the current working
# directory is the mount point of that partition.
#
# $1: absolute index of the partition to customize
# $2: name of customization handler
# $3..: optional additional args to pass to handler
board_customize_partition ( ) {
    local ABSINDEX=$1
    local CUSTOMIZATION_HANDLER=$2

    shift
    shift

    strategy_add $PHASE_CUSTOMIZE_PARTITION _board_customize_partition $ABSINDEX $CUSTOMIZATION_HANDLER "$@"
}

# $1: absolute index of the partition to get the mount point for
board_mountpoint ( ) {
    local ABSINDEX=$1
    local TYPE
    local RELINDEX
    local MOUNTPOINT_PREFIX

    TYPE=`disk_get_var ${ABSINDEX} TYPE`
    RELINDEX=`disk_get_var ${ABSINDEX} RELINDEX`

    if board_is_boot_partition ${ABSINDEX}; then
	MOUNTPOINT_PREFIX=${BOARD_BOOT_MOUNTPOINT_PREFIX}
    elif board_is_freebsd_partition ${ABSINDEX}; then
	MOUNTPOINT_PREFIX=${BOARD_FREEBSD_MOUNTPOINT_PREFIX}
    else
	MOUNTPOINT_PREFIX=`eval echo \\$BOARD_${TYPE}_MOUNTPOINT_PREFIX`
    fi

    # For the benefit of users who might be used to certain default
    # mountpoint names from the old single-partition-of-a-given-type
    # crochet version, the first partition of a given type has no
    # suffix.
    if [ $RELINDEX -eq 1 ]; then
	echo ${MOUNTPOINT_PREFIX}
    else
	echo ${MOUNTPOINT_PREFIX}.${RELINDEX}
    fi
}

# $1: relative index of FAT partition to get the mount point for, 1 if
#     not specified
board_fat_mountpoint ( ) {
    local RELINDEX=$1
    local ABSINDEX
    
    ABSINDEX=`disk_get_var FAT ${RELINDEX:-1} ABSINDEX`

    board_mountpoint ${ABSINDEX}
}

# $1: relative index of UFS partition to get the mount point for, 1 if
#     not specified
board_ufs_mountpoint ( ) {
    local RELINDEX=$1
    local ABSINDEX
    
    ABSINDEX=`disk_get_var UFS ${RELINDEX:-1} ABSINDEX`

    board_mountpoint ${ABSINDEX}
}


#
# Mount all non-reserved partitions
#
board_mount_all ( ) {
    local ABSINDEX

    echo "Mounting all file systems:"
    
    ABSINDEX=1
    while [ $ABSINDEX -le $DISK_COUNT ]; do
	disk_mount `board_mountpoint ${ABSINDEX}` ${ABSINDEX}
	ABSINDEX=$(( ${ABSINDEX} + 1))
    done
}

