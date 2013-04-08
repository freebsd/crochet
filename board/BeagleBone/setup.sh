KERNCONF=BEAGLEBONE
BEAGLEBONE_UBOOT_SRC=${TOPDIR}/u-boot-beaglebone-freebsd

strategy_add $PHASE_CHECK freebsd_current_test
strategy_add $PHASE_CHECK freebsd_dtc_test

beaglebone_check_uboot ( ) {
    # I used to use the Arago project sources directly, but those
    # change quickly and I got tired of chasing patches.  If you want
    # to try them:
    #
    #uboot_test \
    #   BEAGLEBONE_UBOOT_SRC \
    #   "$BEAGLEBONE_UBOOT_SRC/board/ti/am335x/Makefile" \
    #   "git clone git://arago-project.org/git/projects/u-boot-am33x.git ${BEAGLEBONE_UBOOT_SRC}"

    # I now use a fork of the Arago sources with FreeBSD-specific patches
    # pre-applied:
    uboot_test \
	BEAGLEBONE_UBOOT_SRC \
	"$BEAGLEBONE_UBOOT_SRC/board/ti/am335x/Makefile" \
	"git clone https://github.com/kientzle/u-boot-beaglebone-freebsd.git ${BEAGLEBONE_UBOOT_SRC}"
}

strategy_add $PHASE_CHECK beaglebone_check_uboot


strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build UBLDR_LOADADDR=0x88000000

# One advantage of maintaining a clone of the Arago
# sources:  I can just keep changes there instead
# of managing patches.
#uboot_patch ${BOARDDIR}/files/uboot_*.patch
strategy_add $PHASE_BUILD_OTHER uboot_configure $BEAGLEBONE_UBOOT_SRC am335x_evm_config
strategy_add $PHASE_BUILD_OTHER uboot_build $BEAGLEBONE_UBOOT_SRC

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

beaglebone_populate_boot_partition ( ) {
    # Note that all of the BeagleBone boot files
    # start with 'BB' now (except for MLO, which can't
    # be renamed because it's loaded by the ROM).
    echo "Installing U-Boot onto the FAT partition"
    cp ${BEAGLEBONE_UBOOT_SRC}/MLO .
    cp ${BEAGLEBONE_UBOOT_SRC}/u-boot.img bb-uboot.img
    cp ${BOARDDIR}/files/uEnv.txt bb-uEnv.txt

    # Issue: ubldr is actually board-specific right now, but only
    # because of the link address.  Changing ubldr to a static binary
    # (non-ELF) might address this.
    freebsd_ubldr_copy_ubldr bbubldr
    freebsd_install_fdt beaglebone.dts bbone.dts
    freebsd_install_fdt beaglebone.dts bbone.dtb
}
strategy_add $PHASE_BOOT_INSTALL beaglebone_populate_boot_partition

strategy_add $PHASE_FREEBSD_BASE_INSTALL freebsd_installkernel .
strategy_add $PHASE_FREEBSD_BASE_INSTALL mkdir boot/msdos
strategy_add $PHASE_FREEBSD_BASE_INSTALL freebsd_ubldr_copy_ubldr_help boot
