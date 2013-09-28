TARGET_ARCH=i386
KERNCONF=GENERIC
IMAGE_SIZE=$((600 * 1000 * 1000))

soekris_partition_image ( ) {
    disk_partition_mbr
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW soekris_partition_image                                
                                                                                         
                                                                                         
# copy the loader                                                                        
soekris_board_install ( ) {                                                              
    # install GRUB
    grub_install_grub2
    
    # I386 install loader
    echo "Installing loader(8)"                                                          
    (cd ${WORKDIR} ; find boot | cpio -dump ${BOARD_FREEBSD_MOUNTPOINT})                 
}                                                                                        
#strategy_add $PHASE_FREEBSD_BOARD_INSTALL soekris_board_install                          
                                                                                         
# Kernel installs in UFS partition
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_installkernel .

