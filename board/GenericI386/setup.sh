TARGET_ARCH=i386
KERNCONF=GENERIC

board_check_prerequisites ( ) {
    freebsd_current_test
}

i386_build_mbr ( ) {
    echo "Building MBR"
    cd ${FREEBSD_SRC}/sys/boot/i386/mbr
    make TARGET_ARCH=i386 > ${WORKDIR}/_.i386.mbr.log || exit 1
    make TARGET_ARCH=i386 DESTDIR=${WORKDIR} install || exit 1
}

i386_build_boot2 ( ) {
    echo "Building Boot2"
    cd ${FREEBSD_SRC}/sys/boot/i386/boot2
    make TARGET_ARCH=i386 > ${WORKDIR}/_.i386.boot2.log || exit 1
    make TARGET_ARCH=i386 DESTDIR=${WORKDIR} install || exit 1
}

i386_build_loader ( ) {
    echo "Building Loader"
    cd ${FREEBSD_SRC}/sys/boot/i386/loader
    make TARGET_ARCH=i386 > ${WORKDIR}/_.i386_loader.log || exit 1
    make TARGET_ARCH=i386 DESTDIR=${WORKDIR} NO_MAN=t install || exit 1
}

board_build_bootloader ( ) {
    mkdir -p ${WORKDIR}/boot/defaults
    i386_build_mbr
    i386_build_boot2
    i386_build_loader
}

board_partition_image ( ) {
    disk_partition_mbr
    disk_ufs_create
    echo "Installing bootblocks"
    gpart bootcode -b ${WORKDIR}/boot/mbr ${DISK_MD} || exit 1
    gpart set -a active -i 1 ${DISK_MD} || exit 1
    bsdlabel -B -b ${WORKDIR}/boot/boot ${DISK_UFS_PARTITION} || exit 1
}

board_mount_partitions ( ) {
    disk_ufs_mount ${BOARD_FREEBSD_MOUNTPOINT}
}

board_populate_freebsd_partition ( ) {
    generic_board_populate_freebsd_partition
    echo "Installing loader(8)"
    (cd ${WORKDIR} ; find boot | cpio -dump ${BOARD_FREEBSD_MOUNTPOINT})
}
