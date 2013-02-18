KERNCONF=BEAGLEBONE
UBOOT_SRC=${TOPDIR}/u-boot-beaglebone-freebsd

board_check_prerequisites ( ) {
    freebsd_current_test

    # I used to use the Arago project sources directly, but those
    # change quickly and I got tired of chasing patches.  If you want
    # to try them:
    #
    #uboot_test \
    #   "$UBOOT_SRC/board/ti/am335x/Makefile" \
    #   "git clone git://arago-project.org/git/projects/u-boot-am33x.git ${UBOOT_SRC}"

    # I now use a fork of the Arago sources with FreeBSD-specific patches
    # pre-applied:
    uboot_test \
	"$UBOOT_SRC/board/ti/am335x/Makefile" \
	"git clone https://github.com/kientzle/u-boot-beaglebone-freebsd.git ${UBOOT_SRC}"
}

board_build_bootloader ( ) {
    freebsd_ubldr_build UBLDR_LOADADDR=0x88000000

    # One advantage of maintaining a clone of the Arago
    # sources:  I can just keep changes there instead
    # of managing patches.
    #uboot_patch ${BOARDDIR}/files/uboot_*.patch
    uboot_configure am335x_evm_config
    uboot_build
}

board_construct_boot_partition ( ) {
    FAT_MOUNT=${WORKDIR}/_.mounted_fat
    disk_fat_create 2m
    disk_fat_mount ${FAT_MOUNT}

    echo "Installing U-Boot onto the FAT partition"
    cp ${UBOOT_SRC}/MLO ${FAT_MOUNT}
    cp ${UBOOT_SRC}/u-boot.img ${FAT_MOUNT}
    cp ${BOARDDIR}/bootfiles/uEnv.txt ${FAT_MOUNT}

    freebsd_ubldr_copy_ubldr ${FAT_MOUNT}
    freebsd_install_fdt beaglebone.dts ${FAT_MOUNT}/bbone.dts
    freebsd_install_fdt beaglebone.dts ${FAT_MOUNT}/bbone.dtb

    cd ${FAT_MOUNT}
    customize_boot_partition ${FAT_MOUNT}
    disk_fat_unmount ${FAT_MOUNT}
    unset FAT_MOUNT
}

board_customize_freebsd_partition ( ) {
    mkdir $1/boot/msdos
    freebsd_ubldr_copy_ubldr_help $1/boot
    freebsd_install_fdt beaglebone.dts $1/boot/beaglebone.dts
    freebsd_install_fdt beaglebone.dts $1/boot/beaglebone.dtb
}
