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
    DISK_MD=`mdconfig -a -t vnode -f $1 -x 63 -y 255`
    disk_record_md ${DISK_MD}
}

# Partition the virtual disk using MBR.
#
# (ROM code for TI AM335X and Raspberry PI both require MBR
# partitioning.)
#
disk_partition_mbr ( ) {
    echo "Partitioning the raw disk image with MBR at "`date`
    echo gpart create -s MBR ${DISK_MD}
    gpart create -s MBR ${DISK_MD}
}

# $1: mount directory
disk_prep_mountdir ( ) {
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
}

#
# Get the count of disks of the given type, or total disks if no type
# specified
#
# $1: Optional type (e.g., FAT, RESERVED, UFS)
disk_count ( ) {
    local TYPE=$1
    local TYPE_COUNT

    if [ -z "$TYPE" ]; then
	echo ${DISK_COUNT:-0}
    else
	TYPE_COUNT=`eval echo \\$DISK_${TYPE}_COUNT`
	echo ${TYPE_COUNT:-0}
    fi
}

#
# Get value for variable with the given name from the given disk
# index, which is relative to the given type, or absolute if the type
# is omitted or empty.
#
# disk_get_var [type] index varname
#
disk_get_var ( ) {
    local TYPE
    local ABSINDEX
    local VARNAME

    if [ $# -eq 3 ]; then
	TYPE=$1
	shift
    else
	TYPE=
    fi
    ABSINDEX=$1

    if [ -n "$TYPE" ]; then
	ABSINDEX=`disk_absindex ${TYPE} ${1}`
    fi
    VARNAME=$2

    echo `eval echo \\$DISK_${ABSINDEX}_${VARNAME}`
}


#
# Set variable with the given name to the given value for the given
# disk index, which is relative to the given type, or absolute if the
# type is omitted or empty.
#
# disk_set_var [type] index varname value
#
disk_set_var ( ) {
    local TYPE
    local ABSINDEX
    local VARNAME
    local VALUE

    if [ $# -eq 4 ]; then
	TYPE=$1
	shift
    else
	TYPE=
    fi
    ABSINDEX=$1

    if [ -n "$TYPE" ]; then
	ABSINDEX=`disk_absindex ${TYPE} ${1}`
    fi
    VARNAME=$2
    VALUE=$3

    setvar DISK_${ABSINDEX}_${VARNAME} ${VALUE}
}

#
# Adjust disk counts and set post-creation per-disk info-tracking variables
#
# $1: Type (e.g., FAT, RESERVED, UFS)
# $2: Partition name (a slice or partition-of-slice name, e.g., md0s1 or md0s2a)
disk_created_new ( ) {
    local TYPE=$1
    local NAME=$2
    local ABSINDEX
    local RELINDEX

    DISK_COUNT=$(( `disk_count` + 1 ))
    setvar DISK_${TYPE}_COUNT $(( `disk_count ${TYPE}` + 1 ))

    ABSINDEX=`disk_count`
    RELINDEX=`disk_count ${TYPE}`

    # The absolute index is the only value tracked by type and
    # relative index.
    setvar DISK_${TYPE}_${RELINDEX}_ABSINDEX ${ABSINDEX}

    disk_set_var ${ABSINDEX} TYPE      ${TYPE}
    disk_set_var ${ABSINDEX} RELINDEX  ${RELINDEX}
    disk_set_var ${ABSINDEX} ABSINDEX  ${ABSINDEX}
    disk_set_var ${ABSINDEX} PARTITION ${NAME}
    disk_set_var ${ABSINDEX} DEVICE    /dev/${NAME}

    # The first FAT partition is always considered a boot partition
    if [ \( "$TYPE" = "FAT" \) -a \( ${RELINDEX} -eq 1 \) ]; then
	disk_set_var ${ABSINDEX} BOOT "y"
    fi

    # The first UFS partition always gets FreeBSD installed
    if [ \( "$TYPE" = "UFS" \) -a \( ${RELINDEX} -eq 1 \) ]; then
	disk_set_var ${ABSINDEX} FREEBSD "y"
    fi
}


#
# Get the absolute index for the given type and relative index
#
# disk_absindex type relindex
#
disk_absindex ( ) {
    local TYPE=$1
    local RELINDEX=$2

    echo `eval echo \\$DISK_${TYPE}_${RELINDEX}_ABSINDEX`
}


#
# Get the type (e.g., FAT, RESERVED, UFS) for the given absolute
# partition index
#
# disk_type absindex
#
disk_type ( ) {
    disk_get_var $1 TYPE
}

#
# Get the partition name for the given partition index, which is
# relative to the given type, or absolute if no type is specified.
#
# disk_partition [type] index
#
disk_partition ( ) {
    disk_get_var $1 $2 PARTITION
}

#
# Get the device name for the given partition index, which is relative
# to the given type, or absolute if no type is specified.
#
# disk_device [type] index
#
disk_device ( ) {
    disk_get_var $1 $2 DEVICE
}



# $1: index of RESERVED partition
disk_reserved_device ( ) {
    local INDEX=$1

    disk_device RESERVED ${INDEX:-1}
}

# $1: index of RESERVED partition
disk_reserved_partition ( ) {
    local INDEX=$1

    disk_partition RESERVED ${INDEX:-1}
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

    disk_created_new RESERVED ${_DISK_RESERVED_SLICE}
}

# $1: index of FAT partition
disk_fat_device ( ) {
    local INDEX=$1

    disk_device FAT ${INDEX:-1}
}

# $1: index of FAT partition
disk_fat_partition ( ) {
    local INDEX=$1

    disk_partition FAT ${INDEX:-1}
}


# Add a FAT partition and format it.
#
# $1: size of partition, can use 'k', 'm', 'g' suffixes, or whole disk if -1 or not specified
# $2: '12', '16', or '32' for FAT type (-1 or empty for default, which depends on $1)
# $3: start block (-1 or empty for default of 63)
# $4: label, empty for default of "BOOT"
disk_fat_create ( ) {
    local SIZE_ARG
    local SIZE_DISPLAY="n auto-sized"
    local FAT_LABEL=$4
    local NEW_FAT_SLICE
    local NEW_FAT_DEVICE
    local NEW_FAT_SLICE_NUMBER

    if [ -n "$1" -a \( "$1" != "-1" \) ]; then
	SIZE_ARG="-s $1"
	SIZE_DISPLAY=" $1"
    fi

    if [ -z "${FAT_LABEL}" ]; then
	FAT_LABEL="BOOT"
    fi

    # start block
    FAT_START_BLOCK=$3
    if [ -z "${FAT_START_BLOCK}" -o \( "${FAT_START_BLOCK}" = "-1" \) ]; then
        FAT_START_BLOCK=63
    fi

    echo "Creating a${SIZE_DISPLAY} FAT partition at "`date`" with start block $FAT_START_BLOCK and label ${FAT_LABEL}"

    NEW_FAT_SLICE=`gpart add -a 63 -b ${FAT_START_BLOCK} -s $1 -t '!12' ${DISK_MD} | sed -e 's/ .*//'`
    NEW_FAT_DEVICE=/dev/${NEW_FAT_SLICE}
    NEW_FAT_SLICE_NUMBER=`echo ${NEW_FAT_SLICE} | sed -e 's/.*[^0-9]//'`
    gpart set -a active -i ${NEW_FAT_SLICE_NUMBER} ${DISK_MD}

    # TODO: Select FAT12, FAT16, or FAT32 depending on partition size
    _FAT_TYPE=$2
    if [ -z "${_FAT_TYPE}" -o \( "${_FAT_TYPE}" = "-1" \) ]; then
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

    if [ "${FAT_LABEL}" = "-" ]; then
        newfs_msdos -F ${_FAT_TYPE} ${NEW_FAT_DEVICE} >/dev/null
    else
        newfs_msdos -L ${FAT_LABEL} -F ${_FAT_TYPE} ${NEW_FAT_DEVICE} >/dev/null
    fi

    disk_created_new FAT ${NEW_FAT_SLICE}
}

# $1: Directory where FAT partition will be mounted
# $2: relative index of partition to be mounted, 1 if not specified
disk_fat_mount ( ) {
    echo "Mounting FAT partition ${2:-1} at $1"
    disk_prep_mountdir $1
    mount_msdosfs -l `disk_fat_device $2` $1
    disk_record_mountdir $1
}


# $1: index of UFS partition
disk_ufs_slice ( ) {
    local INDEX=$1
    disk_device UFS ${INDEX:-1} | sed -e 's/\([0-9]\)[a-z]*$/\1/'
}

# $1: index of UFS partition
disk_ufs_device ( ) {
    local INDEX=$1
    disk_device UFS ${INDEX:-1}
}

# $1: index of UFS partition
disk_ufs_partition ( ) {
    local INDEX=$1
    disk_partition UFS ${INDEX:-1}
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

    # 512k alignment helps boot1.efi find UFS.
    NEW_UFS_SLICE=`gpart add -t freebsd -a 512k ${SIZE_ARG} ${DISK_MD} | sed -e 's/ .*//'` || exit 1
    NEW_UFS_SLICE_NUMBER=`echo ${NEW_UFS_SLICE} | sed -e 's/.*[^0-9]//'`

    gpart create -s BSD ${NEW_UFS_SLICE}
    NEW_UFS_PARTITION=`gpart add -t freebsd-ufs -a 64k ${NEW_UFS_SLICE} | sed -e 's/ .*//'` || exit 1

    NEW_UFS_DEVICE=/dev/${NEW_UFS_PARTITION}

    newfs ${NEW_UFS_DEVICE}
    # Turn on Softupdates
    tunefs -n enable ${NEW_UFS_DEVICE}
    # Turn on SUJ with a minimally-sized journal.
    # This makes reboots tolerable if you just pull power
    # Note:  A slow SDHC reads about 1MB/s, so a 30MB
    # journal can delay boot by 30s.
    tunefs -j enable -S 4194304 ${NEW_UFS_DEVICE}
    # Turn on NFSv4 ACLs
    tunefs -N enable ${NEW_UFS_DEVICE}

    disk_created_new UFS ${NEW_UFS_PARTITION}
}

# $1: index of UFS partition
# $2: filesystem label
disk_ufs_label ( ) {
    local UFS_INDEX=$1
    local UFS_LABEL=$2
    local UFS_DEVICE

    if [ -z "$UFS_INDEX" ]; then
	UFS_INDEX=1
    fi

    if [ -n "$UFS_LABEL" ]; then
	UFS_DEVICE=`disk_ufs_device ${UFS_INDEX}`
	echo "Labeling ${UFS_DEVICE} ${UFS_LABEL}"
	tunefs -L ${UFS_LABEL} ${UFS_DEVICE}
    fi
}

# $1: directory where UFS partition will be mounted
# $2: relative index of partition to be mounted, 1 if not specified
disk_ufs_mount ( ) {
    echo "Mounting UFS partition ${2:-1} at $1"
    disk_prep_mountdir $1
    mount `disk_ufs_device $2` $1 || exit 1
    disk_record_mountdir $1
}


#
disk_efi_create ( ) {
    NEW_EFI_PARTITION=`gpart add -t efi -s 800K ${DISK_MD} | sed -e 's/ .*//'` || exit 1
    NEW_EFI_DEVICE=/dev/${NEW_EFI_PARTITION}
	echo "Writing EFI partition to ${NEW_EFI_DEVICE}"
    dd if=${FREEBSD_OBJDIR}/stand/efi/boot1/boot1.efifat of=${NEW_EFI_DEVICE}
}


#
# $1: mount point
# $2: absolute index of partition to mount
disk_mount ( ) {
    local MOUNTPOINT=$1
    local ABSINDEX=$2
    local RELINDEX
    local TYPE

    TYPE=`disk_get_var ${ABSINDEX} TYPE`
    RELINDEX=`disk_get_var ${ABSINDEX} RELINDEX`
    case ${TYPE} in
	FAT)
	    disk_fat_mount ${MOUNTPOINT} ${RELINDEX}
	    ;;
	UFS)
	    disk_ufs_mount ${MOUNTPOINT} ${RELINDEX}
	    ;;
	*)
	    echo "Attempt to mount ${TYPE} partition ${RELINDEX} at ${MOUNTPOINT} failed."
	    echo "Do not know how to mount partitions of type ${TYPE}."
	    exit 1
	    ;;
    esac
}
