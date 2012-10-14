KERNCONF=RPI-B
UBOOT_SRC=${TOPDIR}/u-boot-rpi

# You can use the most up-to-date boot files from the RaspberryPi project:
#RPI_FIRMWARE_SRC=${TOPDIR}/rpi-firmware

# Or save yourself a 400MB+ download and just use the files checked
# into this project:
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
    uboot_patch ${BOARDDIR}/files/uboot_*.patch
    uboot_configure rpi_b_config
    uboot_build

    # Build ubldr.
    freebsd_ubldr_build UBLDR_LOADADDR=0x2000000
}

board_construct_boot_partition ( ) {
    echo "Setting up boot partition"
    FAT_MOUNT=${WORKDIR}/_.mounted_fat
    # Raspberry Pi boot loaders require FAT16, so this must be at least 17m
    disk_fat_create 17m 16
    disk_fat_mount ${FAT_MOUNT}

    # Copy RaspberryPi boot files to FAT partition
    cp ${RPI_FIRMWARE_SRC}/boot/bootcode.bin ${FAT_MOUNT}
    cp ${RPI_FIRMWARE_SRC}/boot/arm192_start.elf ${FAT_MOUNT}/start.elf
    # Configure to chain-load U-Boot
    echo "kernel=u-boot.bin" > ${FAT_MOUNT}/config.txt
    #echo "kernel=freebsd.bin" > ${FAT_MOUNT}/config.txt

    # Copy U-Boot to FAT partition, configure to chain-boot ubldr
    cp ${UBOOT_SRC}/u-boot.bin ${FAT_MOUNT}
    cat > ${FAT_MOUNT}/uEnv.txt <<EOF
loadbootscript=fatload mmc 0 0x2000000 ubldr
bootscript=bootelf 0x2000000
EOF

    # Install ubldr to FAT partition
    freebsd_ubldr_copy ${FAT_MOUNT}

    # Copy kernel.bin to FAT partition
    #FREEBSD_INSTALLKERNEL_BOARD_ARGS='KERNEL_KO=kernel.bin -DWITHOUT_KERNEL_SYMBOLS'
    #mkdir ${WORKDIR}/boot
    #freebsd_installkernel ${WORKDIR}
    #cat ${RPI_FIRMWARE_SRC}/boot/kernel.prefix.img ${WORKDIR}/boot/kernel/kernel.bin > ${FAT_MOUNT}/freebsd.bin

    # DEBUG: list contents of FAT partition
    echo "FAT Partition contents:"
    ls -l ${FAT_MOUNT}

    disk_fat_unmount ${FAT_MOUNT}
    unset FAT_MOUNT
}
