KERNCONF=RPI-B
UBOOT_SRC=${TOPDIR}/u-boot-rpi
RPI_FIRMWARE_SRC=${TOPDIR}/rpi-firmware

board_check_prerequisites ( ) {
    freebsd_current_test

    uboot_test \
	"$UBOOT_SRC/board/raspberrypi/rpi_b/Makefile" \
	"git clone -b rpi_b git://github.com/gonzoua/u-boot-pi.git ${UBOOT_SRC}"

    if [ ! -f "${RPI_FIRMWARE_SRC}/boot/start.elf" ]; then
	echo "Need Rasberry Pi closed-source boot files."
	echo "Use the following command to fetch them:"
	echo
	echo " $ git clone git://github.com/raspberrypi/firmware ${RPI_FIRMWARE_SRC}"
	echo
	echo "Run this script again after you have the files."
	exit 1
    fi
}

board_build_bootloader ( ) {
    # Closed-source firmware is already built.

    # Build U-Boot
    # TODO: Figure out any needed patches
    # uboot_patch ${BOARDDIR}/files/uboot_*.patch
    uboot_configure rpi_b_config
    uboot_build

    # Build ubldr.
    # TODO: the loadaddr here is probably wrong.
    freebsd_ubldr_build UBLDR_LOADADDR=0x88000000
}

board_construct_boot_partition ( ) {
    echo "Setting up boot partition"
    FAT_MOUNT=${WORKDIR}/_.mounted_fat
    disk_fat_create 8m
    disk_fat_mount ${FAT_MOUNT}

    # Copy Phase One boot files to FAT partition
    cd ${RPI_FIRMWARE_SRC}/boot
    cp bootcode.bin ${FAT_MOUNT}
    cp loader.bin ${FAT_MOUNT}
    cp arm192_start.elf ${FAT_MOUNT}/start.elf

    # Copy U-Boot and ubldr to FAT partition
    cp ${UBOOT_SRC}/u-boot.img ${FAT_MOUNT}
    cp ${BOARDDIR}/files/uEnv.txt ${FAT_MOUNT}
    freebsd_ubldr_copy ${FAT_MOUNT}

    disk_fat_unmount ${FAT_MOUNT}
    unset FAT_MOUNT
}
