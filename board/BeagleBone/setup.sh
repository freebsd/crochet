KERNCONF=BEAGLEBONE
UBOOT_SRC=${TOPDIR}/u-boot-ti

check_prerequisites ( ) {
    freebsd_current_test

    uboot_test \
	"$UBOOT_SRC/board/ti/am335x/Makefile" \
	"git clone git://arago-project.org/git/projects/u-boot-am33x.git ${UBOOT_SRC}"
}

build_bootloader ( ) {
    freebsd_ubldr_build UBLDR_LOADADDR=0x88000000
    uboot_patch ${BOARDDIR}/files/uboot_*.patch
    uboot_configure am335x_evm_config
    uboot_build
}

construct_boot_partition ( ) {
    FAT_MOUNT=${WORKDIR}/_.mounted_fat
    disk_fat_format
    disk_fat_mount ${FAT_MOUNT}

    echo "Installing U-Boot onto the FAT partition"
    cp ${UBOOT_SRC}/MLO ${FAT_MOUNT}
    cp ${UBOOT_SRC}/u-boot.img ${FAT_MOUNT}
    cp ${BOARDDIR}/files/uEnv.txt ${FAT_MOUNT}

    freebsd_ubldr_copy ${FAT_MOUNT}

    disk_fat_unmount ${FAT_MOUNT}
    unset FAT_MOUNT
}
