KERNCONF=PANDABOARD
PANDABOARD_UBOOT_SRC=${TOPDIR}/u-boot-panda

board_check_prerequisites ( ) {
    freebsd_current_test

    uboot_test \
	PANDABOARD_UBOOT_SRC \
	"$UBOOT_SRC/board/ti/panda/Makefile" \
	"fetch ftp://ftp.denx.de/pub/u-boot/u-boot-2012.07.tar.bz2" \
	"tar xf u-boot-2012.07.tar.bz2"
}

board_build_bootloader ( ) {
    freebsd_ubldr_build UBLDR_LOADADDR=0x88000000

    uboot_patch ${PANDABOARD_UBOOT_SRC} ${BOARDDIR}/files/uboot_*.patch
    uboot_configure ${PANDABOARD_UBOOT_SRC} omap4_panda
    uboot_build ${PANDABOARD_UBOOT_SRC}
}

board_construct_boot_partition ( ) {
    FAT_MOUNT=${WORKDIR}/_.mounted_fat
    disk_fat_create 8m
    disk_fat_mount ${FAT_MOUNT}
    echo "Installing U-Boot onto the FAT partition"
    # For now, we use a copy of an MLO built by someone else.
    cp ${BOARDDIR}/boot/MLO ${FAT_MOUNT}
    # TODO: We should be able to use MLO built by U-Boot. <sigh>
    #cp ${UBOOT_SRC}/MLO ${FAT_MOUNT}
    cp ${UBOOT_SRC}/u-boot.bin ${FAT_MOUNT}

    freebsd_ubldr_copy ${FAT_MOUNT}

    disk_fat_unmount ${FAT_MOUNT}
    unset FAT_MOUNT
}
