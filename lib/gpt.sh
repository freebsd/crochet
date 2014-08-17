
# Partition the virtual disk using GPT.
#
#
disk_partition_gpt ( ) {
    echo "Partitioning the raw disk image with EFI/GPT at "`date`
    gpart create -s GPT ${DISK_MD}
}

#
# add a GPT FAT parition
# $1: size of parition
#
gpt_add_fat_partition ( ) {
    local NEW_FAT_SLICE=`gpart add -b 17m -s $1 -t '!EBD0A0A2-B9E5-4433-87C0-68B6B72699C7' /dev/${DISK_MD} | sed -e 's/ .*//'`
    local NEW_FAT_DEVICE=/dev/${NEW_FAT_SLICE}
    echo "FAT partition is ${NEW_FAT_DEVICE}"
    newfs_msdos ${NEW_FAT_DEVICE} >/dev/null
    disk_created_new FAT ${NEW_FAT_SLICE}
}

# add a GPT UFS parition
# parition consumes the entire disk which is not already used
gpt_add_ufs_partition ( ) {
    local NEW_UFS_SLICE=`gpart add -t freebsd-ufs /dev/${DISK_MD} | sed -e 's/ .*//'`
    local NEW_UFS_DEVICE=/dev/${NEW_UFS_SLICE}
    echo "UFS partition is ${NEW_UFS_DEVICE}"
    newfs ${NEW_UFS_DEVICE} >/dev/null
    disk_created_new UFS ${NEW_UFS_SLICE}
}