TARGET_ARCH=i386
KERNCONF=GENERIC
IMAGE_SIZE=$((600 * 1000 * 1000))

soekris_build_loader ( ) {
    echo "Building Loader"
    cd ${FREEBSD_SRC}/sys/boot/i386/loader
    make TARGET_ARCH=i386 > ${WORKDIR}/_.i386_loader.log || exit 1
    make TARGET_ARCH=i386 DESTDIR=${WORKDIR} NO_MAN=t install || exit 1
}
strategy_add $PHASE_BUILD_OTHER soekris_build_loader

soekris_partition_image ( ) {
    disk_partition_mbr
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW soekris_partition_image

# Install grub
strategy_add $PHASE_PARTITION_LWW grub_install_grub2

# copy the loader
soekris_board_install ( ) {
    # I386 images expect a copy of all the boot bits in /boot
    echo "Installing loader(8)"
    (cd ${WORKDIR} ; find boot | cpio -dump ${BOARD_FREEBSD_MOUNTPOINT})
}
strategy_add $PHASE_FREEBSD_BOARD_INSTALL soekris_board_install

# Kernel installs in UFS partition
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_installkernel .

