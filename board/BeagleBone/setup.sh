KERNCONF=BEAGLEBONE
BEAGLEBONE_UBOOT_SRC=${TOPDIR}/u-boot-beaglebone-freebsd

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

beaglebone_populate_boot_partition ( ) {
    # Note that all of the BeagleBone boot files
    # start with 'BB' now (except for MLO, which can't
    # be renamed because it's loaded by the ROM).
    echo "Installing U-Boot onto the FAT partition"
    cp ${BEAGLEBONE_UBOOT_SRC}/MLO ${FAT_MOUNT}
    cp ${BEAGLEBONE_UBOOT_SRC}/u-boot.img ${FAT_MOUNT}/bb-uboot.img
    cp ${BOARDDIR}/bootfiles/uEnv.txt ${FAT_MOUNT}/bb-uEnv.txt

    freebsd_ubldr_copy_ubldr ${FAT_MOUNT}/ubldr
    freebsd_install_fdt beaglebone.dts ${FAT_MOUNT}/bbone.dts
    freebsd_install_fdt beaglebone.dts ${FAT_MOUNT}/bbone.dtb

    # Temporary redundant copies for backwards compatibility.
    cp ${BEAGLEBONE_UBOOT_SRC}/u-boot.img ${FAT_MOUNT}/u-boot.img
    freebsd_ubldr_copy_ubldr ${FAT_MOUNT}/ubldr
    cp ${BOARDDIR}/bootfiles/uEnv.txt ${FAT_MOUNT}/uenv.txt
}

board_construct_boot_partition ( ) {
    FAT_MOUNT=${WORKDIR}/_.mounted_fat
    disk_fat_create 2m
    disk_fat_mount ${FAT_MOUNT}

    beaglebone_populate_boot_partition ${FAT_MOUNT}

    cd ${FAT_MOUNT}
    customize_boot_partition ${FAT_MOUNT}
    disk_fat_unmount ${FAT_MOUNT}
    unset FAT_MOUNT
}

board_customize_freebsd_partition ( ) {
    mkdir $1/boot/msdos
    freebsd_ubldr_copy_ubldr_help $1/boot

    # XXX For experimentation, put a copy of the DTS/DTB in /boot
    freebsd_install_fdt beaglebone.dts $1/boot/beaglebone.dts
    freebsd_install_fdt beaglebone.dts $1/boot/beaglebone.dtb
}
