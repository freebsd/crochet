KERNCONF=BEAGLEBONE
UBOOT_SRC=${TOPDIR}/u-boot-2012.07

board_check_prerequisites ( ) {
    freebsd_current_test

    uboot_test \
	"$UBOOT_SRC/board/ti/panda/Makefile" \
	"fetch ftp://ftp.denx.de/pub/u-boot/u-boot-2012.07.tar.bz2" \
	"tar xf u-boot-2012.07.tar.bz2"
}

board_build_bootloader ( ) {
    freebsd_ubldr_build UBLDR_LOADADDR=0x88000000

    uboot_patch ${BOARDDIR}/files/uboot_*.patch
    uboot_configure omap4_panda
    uboot_build
}

board_construct_boot_partition ( ) {
    FAT_MOUNT=${WORKDIR}/_.mounted_fat
    disk_fat_create 2m
    disk_fat_mount ${FAT_MOUNT}

    echo "Installing U-Boot onto the FAT partition"
    cp ${UBOOT_SRC}/MLO ${FAT_MOUNT}
    cp ${UBOOT_SRC}/u-boot.img ${FAT_MOUNT}
    #cp ${BOARDDIR}/bootfiles/MLO ${FAT_MOUNT}
    #cp ${BOARDDIR}/bootfiles/u-boot.img ${FAT_MOUNT}
    cp ${BOARDDIR}/bootfiles/uEnv.txt ${FAT_MOUNT}

    freebsd_ubldr_copy ${FAT_MOUNT}

    disk_fat_unmount ${FAT_MOUNT}
    unset FAT_MOUNT
}
