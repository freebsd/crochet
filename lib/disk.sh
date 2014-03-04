# $1 - dir to unmount and delete
disk_unmount_dir ( ) {
    echo "Unmounting $1"
    umount $1 || true
    rmdir $1 || true
}

# $1 - md to release
disk_release_md ( ) {
    echo "Releasing $1"
    mdconfig -d -u  $1 || true
}

_DISK_MDS=""  # List of MDs to clean up
_DISK_MOUNTED_DIRS=""  # List of things to be unmounted when we're done
disk_unmount_all ( ) {
    cd ${TOPDIR}
    for d in ${_DISK_MOUNTED_DIRS}; do
	disk_unmount_dir $d
    done
    _DISK_MOUNTED_DIRS=""
    for d in ${_DISK_MDS}; do
	disk_release_md $d
    done
    _DISK_MDS=""
}

# $1 - mount that should be cleaned up on exit.
disk_record_mountdir ( ) {
    _DISK_MOUNTED_DIRS="${_DISK_MOUNTED_DIRS} $1"
}

# $1 - md that should be cleaned up on exit.
disk_record_md ( ) {
    _DISK_MDS="${_DISK_MDS} $1"
}

strategy_add $PHASE_UNMOUNT_LWW disk_unmount_all

# $1: full path of image file
# $2: size of SD image
disk_create_image ( ) {
    local SIZE_DISPLAY="$(($2 / 1000000))MB"
    echo "Creating a ${SIZE_DISPLAY} raw disk image in:"
    echo "    $1"
    [ -f $1 ] && rm -f $1
    dd if=/dev/zero of=$1 bs=512 seek=$(($2 / 512)) count=0 >/dev/null 2>&1
    DISK_MD=`mdconfig -a -t vnode -f $1`
    disk_record_md ${DISK_MD}
}

# Partition the virtual disk using MBR.
#
# (ROM code for TI AM335X and Raspberry PI both require MBR
# partitioning.)
#
disk_partition_mbr ( ) {
    echo "Partitioning the raw disk image at "`date`
    echo gpart create -s MBR ${DISK_MD}
    gpart create -s MBR ${DISK_MD}
}

#
# Add a reserve partition
#
# $1 size of partition
#
disk_reserved_create( ) {
    echo "Creating reserve partition at "`date`" of size $1"
    _DISK_RESERVED_SLICE=`gpart add -a 63 -s $1 -t '!12' ${DISK_MD} | sed -e 's/ .*//'`
    DISK_RESERVED_DEVICE=/dev/${_DISK_RESERVED_SLICE}
}

# Add a FAT partition and format it.
#
# $1: size of partition, can use 'k', 'm', 'g' suffixes, or whole disk if -1 or not specified
# $2: '12', '16', or '32' for FAT type (-1 or empty for default, which depends on $1)
# $3: start block, -1 for default of 63
# $4: label, empty for default of "BOOT"
disk_fat_create ( ) {
    local SIZE_ARG
    local SIZE_DISPLAY="n auto-sized"
    local FAT_LABEL=$4

    if [ -n "$1" -a \( "$1" != "-1" \) ]; then
	SIZE_ARG="-s $1"
	SIZE_DISPLAY=" $1"
    fi

    if [ -z ${FAT_LABEL} ]; then
	FAT_LABEL="BOOT"
    fi

    # start block
    FAT_START_BLOCK=$3
    if [ -z ${FAT_START_BLOCK} -o \( ${FAT_START_BLOCK} -eq -1 \) ]; then
        FAT_START_BLOCK=63
    fi
    echo "Creating a${SIZE_DISPLAY} FAT partition at "`date`" with start block $FAT_START_BLOCK and label ${FAT_LABEL}"
    _DISK_FAT_SLICE=`gpart add -a 63 -b ${FAT_START_BLOCK} -s $1 -t '!12' ${DISK_MD} | sed -e 's/ .*//'`
    DISK_FAT_DEVICE=/dev/${_DISK_FAT_SLICE}
    DISK_FAT_SLICE_NUMBER=`echo ${_DISK_FAT_SLICE} | sed -e 's/.*[^0-9]//'`
    gpart set -a active -i ${DISK_FAT_SLICE_NUMBER} ${DISK_MD}

    # TODO: Select FAT12, FAT16, or FAT32 depending on partition size
    _FAT_TYPE=$2
    if [ -z ${_FAT_TYPE} -o \( ${_FAT_TYPE} -eq -1 \) ]; then
        case $1 in
            *k | [1-9]m | 1[0-6]m) _FAT_TYPE=12
                ;;
            *m) _FAT_TYPE=16
                ;;
            *g) _FAT_TYPE=32
                ;;
        esac
        echo "Default to FAT${_FAT_TYPE} for partition size $1"
    fi

    newfs_msdos -L ${FAT_LABEL} -F ${_FAT_TYPE} ${DISK_FAT_DEVICE} >/dev/null
}

# $1: Directory where FAT partition will be mounted
disk_fat_mount ( ) {
    echo "Mounting FAT partition"
    if [ -d "$1" ]; then
        echo "   Removing already-existing mount directory."
        umount $1 || true
        if rmdir $1; then
            echo "   Removed pre-existing mount directory; creating new one."
        else
            echo "Error: Unable to remove pre-existing mount directory?"
            echo "   $1"
            exit 1
        fi
    fi
    mkdir $1
    mount_msdosfs ${DISK_FAT_DEVICE} $1
    disk_record_mountdir $1
}

# $1: index of UFS partition
disk_ufs_device ( ) {
    local PARTITION_INDEX=$1

    if [ -z "$PARTITION_INDEX" ]; then
	PARTITION_INDEX=1
    fi

    echo `eval echo \\$DISK_UFS_DEVICE_${PARTITION_INDEX}`
}

# $1: index of UFS partition
disk_ufs_partition ( ) {
    local PARTITION_INDEX=$1

    if [ -z "$PARTITION_INDEX" ]; then
	PARTITION_INDEX=1
    fi

    echo `eval echo \\$DISK_UFS_PARTITION_${PARTITION_INDEX}`
}

disk_creating_new_ufs_partition ( ) {
    DISK_UFS_COUNT=$(( ${DISK_UFS_COUNT:-0} + 1 ))
}

# $1: size of partition, uses remainder of disk if not specified
disk_ufs_create ( ) {
    local SIZE_ARG
    local SIZE_DISPLAY="n auto-sized"
    local NEW_UFS_SLICE
    local NEW_UFS_SLICE_NUMBER
    local NEW_UFS_PARTITION
    local NEW_UFS_DEVICE
    
    if [ -n "$1" ]; then
	SIZE_ARG="-s $1"
	SIZE_DISPLAY=" $1"
    fi

    echo "Creating a${SIZE_DISPLAY} UFS partition at "`date`

    disk_creating_new_ufs_partition

    NEW_UFS_SLICE=`gpart add -t freebsd ${SIZE_ARG} ${DISK_MD} | sed -e 's/ .*//'` || exit 1
    NEW_UFS_SLICE_NUMBER=`echo ${NEW_UFS_SLICE} | sed -e 's/.*[^0-9]//'`

    gpart create -s BSD ${NEW_UFS_SLICE}
    NEW_UFS_PARTITION=`gpart add -t freebsd-ufs ${NEW_UFS_SLICE} | sed -e 's/ .*//'` || exit 1

    NEW_UFS_DEVICE=/dev/${NEW_UFS_PARTITION}

    newfs ${NEW_UFS_DEVICE}
    # Turn on Softupdates
    tunefs -n enable ${NEW_UFS_DEVICE}
    # Turn on SUJ with a minimally-sized journal.
    # This makes reboots tolerable if you just pull power on the BB
    # Note:  A slow SDHC reads about 1MB/s, so a 30MB
    # journal can delay boot by 30s.
    tunefs -j enable -S 4194304 ${NEW_UFS_DEVICE}
    # Turn on NFSv4 ACLs
    tunefs -N enable ${NEW_UFS_DEVICE}

    setvar DISK_UFS_PARTITION_${DISK_UFS_COUNT} ${NEW_UFS_PARTITION}
    setvar DISK_UFS_DEVICE_${DISK_UFS_COUNT} ${NEW_UFS_DEVICE}
}

# $1: index of UFS partition
# $2: filesystem label
disk_ufs_label ( ) {
    local PARTITION_INDEX=$1
    local UFS_LABEL=$2
    local UFS_DEVICE

    if [ -z "$PARTITION_INDEX" ]; then
	PARTITION_INDEX=1
    fi

    if [ -n "$UFS_LABEL" ]; then
	UFS_DEVICE=`disk_ufs_device ${PARTITION_INDEX}`
	echo "Labeling ${UFS_DEVICE} ${UFS_LABEL}" 
	tunefs -L ${UFS_LABEL} ${UFS_DEVICE}
    fi
}

# $1: directory where UFS partition will be mounted
# $2: index of partition to be mounted, 1 if not specified
disk_ufs_mount ( ) {
    echo "Mounting UFS partition ${2:-1} at $1"
    if [ -d "$1" ]; then
        echo "   Removing already-existing mount directory."
        umount $1 || true
        if rmdir $1; then
            echo "   Removed pre-existing mount directory; creating new one."
        else
            echo "Error: Unable to remove pre-existing mount directory?"
            echo "   $1"
            exit 1
        fi
    fi
    mkdir $1 || exit 1
    mount `disk_ufs_device $2` $1 || exit 1
    disk_record_mountdir $1
}

