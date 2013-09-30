TARGET_ARCH=i386
KERNCONF=GENERIC
IMAGE_SIZE=$((1024 * 1000 * 1000))

# make sure we have GRUB
strategy_add $PHASE_CHECK grub_check_install

# create a MBR disk with a single UFS partition
soekris_partition_image ( ) {
    disk_partition_mbr
    soekris_ufs_create
}
strategy_add $PHASE_PARTITION_LWW soekris_partition_image                                
                                                                                         
# install the GRUB loader                                                                        
soekris_board_install ( ) {
    # install GRUB
    grub_install_grub
    # configure grub
#    grub_configure_grub
}                                                                                        
strategy_add $PHASE_FREEBSD_BOARD_INSTALL soekris_board_install                          

# create a UFS partition.  We pass -b128 here to make room for the GRUB image.
soekris_ufs_create ( ) {
    echo "Creating the UFS partition at "`date`

    _DISK_UFS_SLICE=`gpart add -b 128 -t freebsd ${DISK_MD} | sed -e 's/ .*//'` || exit 1
    DISK_UFS_SLICE_NUMBER=`echo ${_DISK_UFS_SLICE} | sed -e 's/.*[^0-9]//'`

    gpart create -s BSD ${_DISK_UFS_SLICE}
    DISK_UFS_PARTITION=`gpart add -t freebsd-ufs ${_DISK_UFS_SLICE} | sed -e 's/ .*//'` || exit 1

    DISK_UFS_DEVICE=/dev/${DISK_UFS_PARTITION}

    newfs ${DISK_UFS_DEVICE}
}
                                                                                         
# Kernel installs in UFS partition
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_installkernel .


