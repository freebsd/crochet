KERNCONF=BEAGLEBONE
UBOOT_SRC=${TOPDIR}/u-boot-2012.07

check_prerequisites ( ) {
    freebsd_current_test

    # I used to use the TI Arago sources, but those are pretty
    # regularly broken, and I got tired of chasing patches.  If you
    # want to try them:
    #
    # "git clone git://arago-project.org/git/projects/u-boot-am33x.git ${UBOOT_SRC}"

    uboot_test \
	"$UBOOT_SRC/board/ti/am335x/Makefile" \
	"fetch ftp://ftp.denx.de/pub/u-boot/u-boot-2012.07.tar.bz2" \
	"tar xf u-boot-2012.07.tar.bz2"
}

build_bootloader ( ) {
    freebsd_ubldr_build UBLDR_LOADADDR=0x88000000
    uboot_patch ${BOARDDIR}/files/uboot_*.patch
    uboot_configure am335x_evm_config
    uboot_build
}

construct_boot_partition ( ) {
    FAT_MOUNT=${WORKDIR}/_.mounted_fat
    disk_fat_create 2m
    disk_fat_mount ${FAT_MOUNT}

    echo "Installing U-Boot onto the FAT partition"
    cp ${UBOOT_SRC}/MLO ${FAT_MOUNT}
    cp ${UBOOT_SRC}/u-boot.img ${FAT_MOUNT}
    cp ${BOARDDIR}/files/uEnv.txt ${FAT_MOUNT}

    freebsd_ubldr_copy ${FAT_MOUNT}

    disk_fat_unmount ${FAT_MOUNT}
    unset FAT_MOUNT
}
