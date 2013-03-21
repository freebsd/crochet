KERNCONF=PANDABOARD
PANDABOARD_UBOOT_SRC=${TOPDIR}/u-boot-2012.07

board_check_prerequisites ( ) {
    freebsd_current_test

    uboot_test \
	PANDABOARD_UBOOT_SRC \
	"${PANDABOARD_UBOOT_SRC}/board/ti/panda/Makefile" \
	"fetch ftp://ftp.denx.de/pub/u-boot/u-boot-2012.07.tar.bz2" \
	"tar xf u-boot-2012.07.tar.bz2"
}

board_build_bootloader ( ) {
    freebsd_ubldr_build UBLDR_LOADADDR=0x88000000

    uboot_patch ${PANDABOARD_UBOOT_SRC} ${BOARDDIR}/files/uboot_*.patch
    uboot_configure ${PANDABOARD_UBOOT_SRC} omap4_panda
    uboot_build ${PANDABOARD_UBOOT_SRC}
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

board_populate_boot_partition ( ) {
    echo "Installing U-Boot onto the boot partition"
    # For now, we use a copy of an MLO built by someone else.
    cp ${BOARDDIR}/boot/MLO ${BOARD_BOOT_MOUNTPOINT}
    # TODO: We should be able to use MLO built by U-Boot. <sigh>
    #cp ${UBOOT_SRC}/MLO ${FAT_MOUNT}
    cp ${PANDABOARD_UBOOT_SRC}/u-boot.bin ${BOARD_BOOT_MOUNTPOINT}

    freebsd_ubldr_copy ${BOARD_BOOT_MOUNTPOINT}
}

board_populate_freebsd_partition ( ) {
    generic_board_populate_freebsd_partition
    mkdir ${BOARD_FREEBSD_MOUNTPOINT}/boot/msdos
    freebsd_ubldr_copy_ubldr_help ${BOARD_FREEBSD_MOUNTPOINT}/boot
}
