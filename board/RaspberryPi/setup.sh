KERNCONF=RPI-B
UBOOT_SRC=${TOPDIR}/u-boot-rpi
# Use boot files checked into this project;
# avoid a 400MB+ download.
#RPI_FIRMWARE_SRC=${TOPDIR}/rpi-firmware
RPI_FIRMWARE_SRC=${BOARDDIR}

raspberry_pi_firmware_check ( ) {
    if [ ! -f "${RPI_FIRMWARE_SRC}/boot/bootcode.bin" ]; then
	echo "Need Rasberry Pi closed-source boot files."
	echo "Use the following command to fetch them:"
	echo
	echo " $ git clone git://github.com/raspberrypi/firmware ${RPI_FIRMWARE_SRC}"
	echo
	echo "Run this script again after you have the files."
	exit 1
    fi
}

board_check_prerequisites ( ) {
    freebsd_current_test

    uboot_test \
	"$UBOOT_SRC/board/raspberrypi/rpi_b/Makefile" \
	"git clone git://github.com/gonzoua/u-boot-pi.git ${UBOOT_SRC}"

    raspberry_pi_firmware_check
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
    #freebsd_ubldr_build UBLDR_LOADADDR=0x88000000
}

board_construct_boot_partition ( ) {
    echo "Setting up boot partition"
    FAT_MOUNT=${WORKDIR}/_.mounted_fat
    # Raspberry Pi boot loaders require FAT16
    disk_fat_create 17m 16
    disk_fat_mount ${FAT_MOUNT}

    # Copy Phase One boot files to FAT partition
    cd ${RPI_FIRMWARE_SRC}/boot
    cp bootcode.bin ${FAT_MOUNT}
    cp arm192_start.elf ${FAT_MOUNT}/start.elf

    # Temporary test: put a Linux kernel so we can verify that above works.
    cp kernel.img ${FAT_MOUNT}

    # Copy U-Boot to FAT partition
    #cp uEnv.txt ${FAT_MOUNT}
    #cp u-boot.bin ${FAT_MOUNT}
    #cp boot.scr ${FAT_MOUNT}

    # TODO: Modify U-Boot to chain-boot ubldr
    #freebsd_ubldr_copy ${FAT_MOUNT}

    # Copy kernel.bin to FAT partition
    FREEBSD_INSTALLKERNEL_BOARD_ARGS='KERNEL_KO=kernel.bin -DWITHOUT_KERNEL_SYMBOLS'
    mkdir ${WORKDIR}/boot
    #freebsd_installkernel ${WORKDIR}
    #cp ${WORKDIR}/boot/kernel/kernel.bin ${FAT_MOUNT}/kernel.img

    # DEBUG: list contents of FAT partition
    cd ${FAT_MOUNT}
    echo "FAT Partition contents:"
    ls -l

    cd ${TOPDIR}

    disk_fat_unmount ${FAT_MOUNT}
    unset FAT_MOUNT
}
