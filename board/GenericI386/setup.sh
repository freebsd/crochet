TARGET_ARCH=i386
KERNCONF=GENERIC
IMAGE_SIZE=$((1000 * 1000 * 1000))

#
# Builds a basic i386 image.
#

# Clean out any old i386 boot bits.
rm -rf ${WORKDIR}/boot
mkdir -p ${WORKDIR}/boot/defaults

#
# Note that the 'build' functions here all do a fake 'install' to
# ${WORKDIR}/boot so we can copy single files to the final image
# without having to hardcode deep paths into the FreeBSD source or
# object tree.
#

generic_i386_build_mbr ( ) {
    echo "Building MBR"
    cd ${FREEBSD_SRC}/sys/boot/i386/mbr
    make TARGET_ARCH=i386 > ${WORKDIR}/_.i386.mbr.log || exit 1
    make TARGET_ARCH=i386 DESTDIR=${WORKDIR} install || exit 1
}
strategy_add $PHASE_BUILD_OTHER generic_i386_build_mbr

generic_i386_build_boot2 ( ) {
    echo "Building Boot2"
    cd ${FREEBSD_SRC}/sys/boot/i386/boot2
    make TARGET_ARCH=i386 > ${WORKDIR}/_.i386.boot2.log || exit 1
    make TARGET_ARCH=i386 DESTDIR=${WORKDIR} install || exit 1
}
strategy_add $PHASE_BUILD_OTHER generic_i386_build_boot2

generic_i386_build_loader ( ) {
    echo "Building Loader"
    cd ${FREEBSD_SRC}/sys/boot/i386/loader
    make TARGET_ARCH=i386 > ${WORKDIR}/_.i386_loader.log || exit 1
    make TARGET_ARCH=i386 DESTDIR=${WORKDIR} NO_MAN=t install || exit 1
}
strategy_add $PHASE_BUILD_OTHER generic_i386_build_loader

# Even though there's only the default partition, we have
# to do extra work here to set all the boot bits.
# DISK_MD and DISK_UFS_PARTITION are set by the helper
# functions in lib/disk.sh.
generic_i386_partition_image ( ) {
    disk_partition_mbr
    disk_ufs_create
    echo "Installing bootblocks"
    gpart bootcode -b ${WORKDIR}/boot/mbr ${DISK_MD} || exit 1
    gpart set -a active -i 1 ${DISK_MD} || exit 1
    bsdlabel -B -b ${WORKDIR}/boot/boot ${DISK_UFS_PARTITION} || exit 1
}
strategy_add $PHASE_PARTITION_LWW generic_i386_partition_image

# Don't need custom mount since the default works for us.

generic_i386_board_install ( ) {
    # I386 images expect all the boot bits in /boot
    echo "Installing loader(8)"
    (cd ${WORKDIR} ; find boot | cpio -dump ${BOARD_FREEBSD_MOUNTPOINT})
}
strategy_add $PHASE_FREEBSD_BOARD_INSTALL generic_i386_board_install
