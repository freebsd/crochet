KERNCONF=BEAGLEBONE
BEAGLEBONE_UBOOT_SRC=${TOPDIR}/u-boot-beaglebone-freebsd
IMAGE_SIZE=$((1000 * 1000 * 1000))

strategy_add $PHASE_CHECK freebsd_current_test

#
# BeagleBone requires a FAT partition to hold the boot loader bits.
#
beaglebone_partition_image ( ) {
    disk_partition_mbr
    disk_fat_create 2m
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW beaglebone_partition_image

beaglebone_mount_partitions ( ) {
    disk_fat_mount ${BOARD_BOOT_MOUNTPOINT}
    disk_ufs_mount ${BOARD_FREEBSD_MOUNTPOINT}
}
strategy_add $PHASE_MOUNT_LWW beaglebone_mount_partitions

#
# BeagleBone uses U-Boot.
#
# I used to use the Arago project sources directly, but those
# change quickly and I got tired of chasing patches.  If you want
# to try them:
# $ git clone git://arago-project.org/git/projects/u-boot-am33x.git ${BEAGLEBONE_UBOOT_SRC}

beaglebone_check_uboot ( ) {
    uboot_test \
	BEAGLEBONE_UBOOT_SRC \
	"$BEAGLEBONE_UBOOT_SRC/board/ti/am335x/Makefile" \
	"git clone https://github.com/kientzle/u-boot-beaglebone-freebsd.git ${BEAGLEBONE_UBOOT_SRC}"
}
strategy_add $PHASE_CHECK beaglebone_check_uboot
# We use freebsd_install_fdt below, so make sure we have dtc installed.
strategy_add $PHASE_CHECK freebsd_dtc_test

# If you want to use the Arago sources, you'll need to patch them.
#uboot_patch ${BOARDDIR}/files/uboot_*.patch
strategy_add $PHASE_BUILD_OTHER uboot_configure $BEAGLEBONE_UBOOT_SRC am335x_evm_config
strategy_add $PHASE_BUILD_OTHER uboot_build $BEAGLEBONE_UBOOT_SRC

beaglebone_uboot_install ( ) {
    # Note that all of the BeagleBone boot files
    # start with 'BB' now (except for MLO, which can't
    # be renamed because it's loaded by the ROM).
    echo "Installing U-Boot onto the FAT partition"
    cp ${BEAGLEBONE_UBOOT_SRC}/MLO .
    cp ${BEAGLEBONE_UBOOT_SRC}/u-boot.img bb-uboot.img
    cp ${BOARDDIR}/files/uEnv.txt bb-uEnv.txt
    freebsd_install_fdt beaglebone.dts bbone.dts
    freebsd_install_fdt beaglebone.dts bbone.dtb
}
strategy_add $PHASE_BOOT_INSTALL beaglebone_uboot_install

# TODO: Try changing ubldr to a PIC binary instead of ELF, so we don't
# have to compile it separately for every different load address.
#
strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build UBLDR_LOADADDR=0x88000000
strategy_add $PHASE_BOOT_INSTALL freebsd_ubldr_copy_ubldr bbubldr
# ubldr help file goes on the UFS partition.
strategy_add $PHASE_FREEBSD_BASE_INSTALL freebsd_ubldr_copy_ubldr_help boot

# BeagleBone puts the kernel on the FreeBSD UFS partition, where it belongs.
strategy_add $PHASE_FREEBSD_BASE_INSTALL freebsd_installkernel .

# Mount the FAT boot partition somewhere useful.
# See overlay/etc/fstab
strategy_add $PHASE_FREEBSD_BASE_INSTALL mkdir boot/msdos
