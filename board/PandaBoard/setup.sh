KERNCONF=PANDABOARD
UBOOT_SRC=${TOPDIR}/u-boot-panda-prebuilt

board_check_prerequisites ( ) {
    freebsd_current_test

    if [ ! -f "${UBOOT_SRC}/u-boot.bin" ]; then
	echo "mkdir ${UBOOT_SRC}"
	echo "cd ${UBOOT_SRC}"
	echo "fetch http://people.freebsd.org/~gonzo/pandaboard/u-boot.bin"
	#echo "fetch http://people.freebsd.org/~gonzo/pandaboard/boot.scr"
	echo "fetch http://people.freebsd.org/~gonzo/pandaboard/MLO"
    fi

# TODO: Need suitable U-Boot sources for Pandaboard
#    uboot_test \
#	"$UBOOT_SRC/board/ti/panda/Makefile" \
#	"fetch ftp://ftp.denx.de/pub/u-boot/u-boot-2012.07.tar.bz2" \
#	"tar xf u-boot-2012.07.tar.bz2"
}

board_build_bootloader ( ) {
    # TODO: Not using ubldr yet, but we can still build it. ;-)
    freebsd_ubldr_build UBLDR_LOADADDR=0x88000000

# TODO: when we have suitable U-Boot sources, we can build it.
#    uboot_patch ${BOARDDIR}/files/uboot_*.patch
#    uboot_configure omap4_panda
#    uboot_build
}

board_construct_boot_partition ( ) {
    FAT_MOUNT=${WORKDIR}/_.mounted_fat
    disk_fat_create 8m
    disk_fat_mount ${FAT_MOUNT}
    echo "Installing U-Boot onto the FAT partition"
    cp ${UBOOT_SRC}/MLO ${FAT_MOUNT}
    cp ${UBOOT_SRC}/u-boot.bin ${FAT_MOUNT}
    cp ${BOARDDIR}/bootfiles/uEnv.txt ${FAT_MOUNT}

    # We install this, even though it isn't used yet.
    freebsd_ubldr_copy ${FAT_MOUNT}

    # TODO: Until we have ubldr working, we have to
    # copy kernel.bin to FAT partition
    FREEBSD_INSTALLKERNEL_BOARD_ARGS='KERNEL_KO=kernel.bin -DWITHOUT_KERNEL_SYMBOLS'
    mkdir ${WORKDIR}/boot
    freebsd_installkernel ${WORKDIR}
    cp ${WORKDIR}/boot/kernel/kernel.bin ${FAT_MOUNT}

    disk_fat_unmount ${FAT_MOUNT}
    unset FAT_MOUNT
}
