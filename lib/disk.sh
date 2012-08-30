

# $1: full path of image file
# $2: size of SD image
disk_create_image ( ) {
    echo "Creating the raw disk image in $1"
    [ -f $1 ] && rm -f $1
    dd if=/dev/zero of=$1 bs=1 seek=$2 count=0 >/dev/null 2>&1
    _DISK_MD=`mdconfig -a -t vnode -f $1`
}

disk_release_image ( ) {
    mdconfig -d -u ${_DISK_MD}
    unset _DISK_MD
}

# Partition the virtual disk using MBR.
#
# (ROM code for TI AM335X and Raspberry PI both require MBR
# partitioning.)
#
disk_partition_mbr ( ) {
    # TODO: Figure out how to include a swap partition here.
    # Swapping to SD is painful, but not as bad as panicing
    # the kernel when you run out of memory.
    echo "Partitioning the raw disk image at "`date`
    gpart create -s MBR -f x ${_DISK_MD}
    gpart add -a 63 -b 63 -s2m -t '!12' -f x ${_DISK_MD}
    gpart set -a active -i 1 -f x ${_DISK_MD}
    _DISK_FAT_PARTITION=s1
    _DISK_FAT_DEV=/dev/${_DISK_MD}${_DISK_FAT_PARTITION}
    gpart add -t freebsd -f x ${_DISK_MD}
    _DISK_UFS_PARTITION=s2
    _DISK_UFS_DEV=/dev/${_DISK_MD}${_DISK_UFS_PARTITION}
    gpart commit ${_DISK_MD}
}

disk_fat_format ( ) {
    echo "Formatting the FAT partition at "`date`
    # TODO: Select FAT12, FAT16, or FAT32 depending on partition size
    newfs_msdos -L "boot" -F 12 ${_DISK_FAT_DEV} >/dev/null
}

# $1: Directory where FAT partition will be mounted
disk_fat_mount ( ) {
    echo "Mounting the virtual FAT partition"
    if [ -d "$1" ]; then
	umount "$1"
	rmdir "$1"
    fi
    mkdir "$1"
    mount_msdosfs ${_DISK_FAT_DEV} "$1"
}

# $1: Mount point
disk_fat_unmount ( ) {
    echo "Unmounting FAT partition"
    umount $1
    rmdir $1
}

disk_ufs_format ( ) {
    echo "Formatting the UFS partition at "`date`
    newfs ${_DISK_UFS_DEV} >/dev/null
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
    if [ -d $1 ]; then
	umount $1
	rmdir $1
    fi
    mkdir $1
    mount ${_DISK_UFS_DEV} $1
}

disk_ufs_unmount ( ) {
    echo "Unmounting the UFS partition at "`date`
    cd $TOPDIR
    umount ${UFS_MOUNT}
    rmdir ${UFS_MOUNT}
    unset UFS_MOUNT
}