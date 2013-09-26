TARGET_ARCH=i386
KERNCONF=SOEKRIS
IMAGE_SIZE=$((600 * 1000 * 1000))

#
# Builds a basic i386 image.
#

# Clean out any old i386 boot bits.
rm -rf ${WORKDIR}/boot
mkdir -p ${WORKDIR}/boot/defaults


generic_i386_partition_image ( ) {
    disk_partition_mbr
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW generic_i386_partition_image


# Kernel installs in UFS partition
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_installkernel .
