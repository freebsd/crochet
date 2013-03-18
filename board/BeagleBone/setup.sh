KERNCONF=BEAGLEBONE
BEAGLEBONE_UBOOT_SRC=${TOPDIR}/u-boot-beaglebone-freebsd

__MAKE_CONF=${BOARDDIR}/make.conf
export __MAKE_CONF

beaglebone_check_prerequisites ( ) {
    freebsd_current_test

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

board_check_prerequisites ( ) {
    beaglebone_check_prerequisites
}

beaglebone_build_bootloader ( ) {
    freebsd_ubldr_build UBLDR_LOADADDR=0x88000000

    # One advantage of maintaining a clone of the Arago
    # sources:  I can just keep changes there instead
    # of managing patches.
    #uboot_patch ${BOARDDIR}/files/uboot_*.patch
    uboot_configure $BEAGLEBONE_UBOOT_SRC am335x_evm_config
    uboot_build $BEAGLEBONE_UBOOT_SRC
}

board_build_bootloader ( ) {
    beaglebone_build_bootloader
}

board_partition_image ( ) {
    disk_partition_mbr
    disk_fat_create 2m
    disk_ufs_create
}

board_mount_partitions ( ) {
    disk_fat_mount ${BOARD_BOOT_MOUNTPOINT}
    disk_ufs_mount ${BOARD_FREEBSD_MOUNTPOINT}
}

beaglebone_populate_boot_partition ( ) {
    # Note that all of the BeagleBone boot files
    # start with 'BB' now (except for MLO, which can't
    # be renamed because it's loaded by the ROM).
    echo "Installing U-Boot onto the FAT partition"
    cp ${BEAGLEBONE_UBOOT_SRC}/MLO ${BOARD_BOOT_MOUNTPOINT}
    cp ${BEAGLEBONE_UBOOT_SRC}/u-boot.img ${BOARD_BOOT_MOUNTPOINT}/bb-uboot.img
    cp ${BOARDDIR}/bootfiles/uEnv.txt ${BOARD_BOOT_MOUNTPOINT}/bb-uEnv.txt

    # Issue: ubldr is actually board-specific right now, but only
    # because of the link address.  Changing ubldr to a static binary
    # (non-ELF) might address this.
    freebsd_ubldr_copy_ubldr ${BOARD_BOOT_MOUNTPOINT}/bbubldr
    freebsd_install_fdt beaglebone.dts ${BOARD_BOOT_MOUNTPOINT}/bbone.dts
    freebsd_install_fdt beaglebone.dts ${BOARD_BOOT_MOUNTPOINT}/bbone.dtb
}

board_populate_boot_partition ( ) {
    beaglebone_populate_boot_partition
}

board_populatee_freebsd_partition ( ) {
    generic_board_populate_freebsd_partition
    mkdir $1/boot/msdos
    freebsd_ubldr_copy_ubldr_help $1/boot
}
