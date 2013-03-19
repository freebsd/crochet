
_DISK_MDS=""  # List of MDs to clean up
_DISK_MOUNTED_DIRS=""  # List of things to be unmounted when we're done
disk_unmount_all ( ) {
    cd ${TOPDIR}
    for d in ${_DISK_MOUNTED_DIRS}; do
	echo "Unmounting $d"
	umount $d
	rmdir $d
    done
    _DISK_MOUNTED_DIRS=""
    for d in ${_DISK_MDS}; do
	mdconfig -d -u  $d
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

# $1: full path of image file
# $2: size of SD image
disk_create_image ( ) {
    echo "Creating the raw disk image in:"
    echo "    $1"
    [ -f $1 ] && rm -f $1
    dd if=/dev/zero of=$1 bs=512 seek=$(($2 / 512)) count=0 >/dev/null 2>&1
    _DISK_MD=`mdconfig -a -t vnode -f $1`
    disk_record_md ${_DISK_MD}
}

# Partition the virtual disk using MBR.
#
# (ROM code for TI AM335X and Raspberry PI both require MBR
# partitioning.)
#
disk_partition_mbr ( ) {
    echo "Partitioning the raw disk image at "`date`
    gpart create -s MBR ${_DISK_MD}
}

# Add a FAT partition and format it.
#
# $1: size of partition, can use 'k', 'm', 'g' suffixes
# TODO: If $1 is empty, use whole disk.
# $2: '12', '16', or '32' for FAT type (default depends on $1)
#
disk_fat_create ( ) {
    echo "Creating the FAT partition at "`date`
    gpart add -a 63 -b 63 -s$1 -t '!12' ${_DISK_MD}
    # TODO: we should get _DISK_FAT_PARTITION from gpart
    # (similar to how mdconfig tells us the MD device we used.)
    _DISK_FAT_PARTITION_NUMBER=1
    _DISK_FAT_PARTITION=s${_DISK_FAT_PARTITION_NUMBER}
    _DISK_FAT_DEV=/dev/${_DISK_MD}${_DISK_FAT_PARTITION}
    gpart set -a active -i ${_DISK_FAT_PARTITION_NUMBER} ${_DISK_MD}

    # TODO: Select FAT12, FAT16, or FAT32 depending on partition size
    _FAT_TYPE=$2
    if [ -z ${_FAT_TYPE} ]; then
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
	
    newfs_msdos -L "boot" -F ${_FAT_TYPE} ${_DISK_FAT_DEV} >/dev/null
}

# $1: Directory where FAT partition will be mounted
disk_fat_mount ( ) {
    echo "Mounting FAT partition"
    if [ -d "$1" ]; then
	echo "   Removing already-existing mount directory."
	umount $1
	rmdir $1
	echo "   Removed pre-existing mount directory; creating new one."
    fi
    mkdir $1
    mount_msdosfs ${_DISK_FAT_DEV} $1
    disk_record_mountdir $1
}

# TODO: Make this work.
disk_swap_create ( ) {
    #gpart add -s790m -t freebsd -i 3 -f x ${_DISK_MD}
    #_DISK_SWAP_PARTITION=s3
}

# TODO: Support $1 size argument
# TODO: If $1 is empty, use whole disk.
disk_ufs_create ( ) {
    echo "Creating the UFS partition at "`date`

    # TODO: Can we obtain the slice information from gpart?
    gpart add -t freebsd ${_DISK_MD}
    _DISK_UFS_SLICE_NUMBER=2
    _DISK_UFS_SLICE=s${_DISK_UFS_SLICE_NUMBER}

    gpart create -s BSD ${_DISK_MD}${_DISK_UFS_SLICE}
    gpart add -t freebsd-ufs ${_DISK_MD}${_DISK_UFS_SLICE}
    _DISK_UFS_PARTITION=${_DISK_UFS_SLICE}a
    _DISK_UFS_DEV=/dev/${_DISK_MD}${_DISK_UFS_PARTITION}

    newfs ${_DISK_UFS_DEV}
    # Turn on Softupdates
    tunefs -n enable ${_DISK_UFS_DEV}
    # Turn on SUJ with a minimally-sized journal.
    # This makes reboots tolerable if you just pull power on the BB
    # Note:  A slow SDHC reads about 1MB/s, so a 30MB
    # journal can delay boot by 30s.
    tunefs -j enable -S 4194304 ${_DISK_UFS_DEV}
    # Turn on NFSv4 ACLs
    tunefs -N enable ${_DISK_UFS_DEV}
}

# $1: directory where UFS partition will be mounted
disk_ufs_mount ( ) {
    echo "Mounting UFS partition"
    if [ -d "$1" ]; then
	echo "   Removing already-existing mount directory."
	umount $1
	rmdir $1
	echo "   Removed pre-existing mount directory; creating new one."
    fi
    mkdir $1 || exit 1
    mount ${_DISK_UFS_DEV} $1 || exit 1
    disk_record_mountdir $1
}

disk_add_swap_file ( ) {
    echo "Creating swap file"
    dd if=/dev/zero of="usr/swap0" bs=1024k count=$1
    chmod 0600 "usr/swap0"
    echo 'swapfile="/usr/swap0"' >> etc/rc.conf
}
