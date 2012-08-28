# $1: full path of image file
# $2: size of SD image
disk_create_image ( ) {
    echo "Creating the raw disk image in $1"
    [ -f $1 ] && rm -f $1
    dd if=/dev/zero of=$1 bs=1 seek=$2 count=0 >/dev/null 2>&1
    MD=`mdconfig -a -t vnode -f $1`
}

disk_release_image ( ) {
    mdcondif -d -u ${MD}
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
    gpart create -s MBR -f x ${MD}
    gpart add -a 63 -b 63 -s2m -t '!12' -f x ${MD}
    gpart set -a active -i 1 -f x ${MD}
    FAT_PART=s1
    FAT_DEV=/dev/${MD}${FAT_PART}
    gpart add -t freebsd -f x ${MD}
    UFS_PART=s2
    UFS_DEV=/dev/${MD}${UFS_PART}
    gpart commit ${MD}
}

disk_fat_format ( ) {
    echo "Formatting the FAT partition at "`date`
    # TODO: Select FAT12, FAT16, or FAT32 depending on partition size
    newfs_msdos -L "boot" -F 12 ${FAT_DEV} >/dev/null
}

disk_fat_mount ( ) {
    echo "Mounting the virtual FAT partition"
    FAT_MOUNT=${BUILDOBJ}/_.mounted_fat
    if [ -d ${FAT_MOUNT} ]; then
	umount ${FAT_MOUNT}
	rmdir ${FAT_MOUNT}
    fi
    mkdir ${FAT_MOUNT}
    mount_msdosfs ${FAT_DEV} ${FAT_MOUNT}
}

disk_fat_unmount ( ) {
    echo "Unmounting FAT partition"
    umount ${FAT_MOUNT}
    rmdir ${FAT_MOUNT}
    unset FAT_MOUNT
}

disk_ufs_format ( ) {
    echo "Formatting the UFS partition at "`date`
    newfs ${UFS_DEV} >/dev/null
    # Turn on Softupdates
    tunefs -n enable ${UFS_DEV}
    # Turn on SUJ with a minimally-sized journal.
    # This makes reboots tolerable if you just pull power on the BB
    # Note:  A slow SDHC reads about 1MB/s, so a 30MB
    # journal can delay boot by 30s.
    tunefs -j enable -S 4194304 ${UFS_DEV}
    # Turn on NFSv4 ACLs
    tunefs -N enable ${UFS_DEV}
}

disk_ufs_mount ( ) {
    echo "Mounting UFS partition"
    UFS_MOUNT=${BUILDOBJ}/_.mounted_ufs
    if [ -d ${UFS_MOUNT} ]; then
	umount ${UFS_MOUNT} || true
	rmdir ${UFS_MOUNT}
    fi
    mkdir ${UFS_MOUNT}
    mount ${UFS_DEV} ${UFS_MOUNT}
}

disk_ufs_unmount ( ) {
    echo "Unmounting the UFS partition at "`date`
    cd $TOPDIR
    umount ${UFS_MOUNT}
    rmdir ${UFS_MOUNT}
    unset UFS_MOUNT
}