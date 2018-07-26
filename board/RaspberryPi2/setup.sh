KERNCONF=GENERIC
UBLDR_LOADADDR=0x2000000
RPI_UBOOT="u-boot-rpi2"
RPI_UBOOT_BIN="u-boot.bin"
RPI_FIRMWARE_PORT="rpi-firmware"
RPI_FIRMWARE_BIN="bootcode.bin"
RPI_FIRMWARE_PATH="${SHARE_PATH}/${RPI_FIRMWARE_PORT}"
RPI_FIRMWARE_FILES="bootcode.bin bcm2709-rpi-2-b.dtb config.txt fixup.dat \
    fixup_cd.dat fixup_db.dat fixup_x.dat overlays start.elf start_cd.elf \
    start_db.elf start_x.elf"
IMAGE_SIZE=$((3 * 1000 * 1000 * 1000)) # 1 GB too small - go with 3 GB default
TARGET_ARCH=armv7
TARGET_CPUTYPE=cortex-a7

UBOOT_PATH="/usr/local/share/u-boot/${RPI_UBOOT}"

raspberry_pi_check_uboot ( ) {
    uboot_port_test ${RPI_UBOOT} ${RPI_UBOOT_BIN}
}
strategy_add $PHASE_CHECK raspberry_pi_check_uboot

rpi_check_firmware ( ) {
    firmware_port_test ${RPI_FIRMWARE_PORT} ${RPI_FIRMWARE_BIN}
}
strategy_add $PHASE_CHECK rpi_check_firmware

# Build ubldr.
strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build UBLDR_LOADADDR=${UBLDR_LOADADDR}

raspberry_pi_partition_image ( ) {
    disk_partition_mbr
    # Use FAT16.  The minimum space requirement for FAT32 is too big for this.
    disk_fat_create 50m 16
    disk_ufs_create
}

strategy_add $PHASE_PARTITION_LWW raspberry_pi_partition_image

raspberry_pi_populate_boot_partition ( ) {
    # Copy RaspberryPi 2 boot files to FAT partition
    cp ${UBOOT_PATH}/README .
    cp ${UBOOT_PATH}/u-boot.bin .
    cp ${UBOOT_PATH}/boot.scr .
    for i in ${RPI_FIRMWARE_FILES}; do
        cp -R ${RPI_FIRMWARE_PATH}/${i} .
    done

    # RPi firmware loads and modify the DTB before pass it to kernel.
    freebsd_install_fdt rpi2.dts rpi2.dtb

    # Install ubldr to FAT partition
    freebsd_ubldr_copy_ubldr .
}

strategy_add $PHASE_BOOT_INSTALL raspberry_pi_populate_boot_partition

strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir boot/msdos
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_ubldr_copy_ubldr boot
