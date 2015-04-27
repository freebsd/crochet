KERNCONF=RPI2
UBLDR_LOADADDR=0x2000000
RPI_UBOOT="u-boot-rpi2"
RPI_UBOOT_BIN="u-boot.bin"
IMAGE_SIZE=$((1000 * 1000 * 1000)) # 1 GB default
TARGET_ARCH=armv6

UBOOT_PATH="/usr/local/share/u-boot/${RPI_UBOOT}"

raspberry_pi_check_uboot ( ) {
    uboot_port_test ${RPI_UBOOT} ${RPI_UBOOT_BIN}
}
strategy_add $PHASE_CHECK raspberry_pi_check_uboot

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
    cp ${UBOOT_PATH}/LICENCE.broadcom .
    cp ${UBOOT_PATH}/README .
    cp ${UBOOT_PATH}/bootcode.bin .
    cp ${UBOOT_PATH}/config.txt .
    cp ${UBOOT_PATH}/fixup.dat .
    cp ${UBOOT_PATH}/fixup_cd.dat .
    cp ${UBOOT_PATH}/fixup_x.dat .
    cp ${UBOOT_PATH}/start.elf .
    cp ${UBOOT_PATH}/start_cd.elf .
    cp ${UBOOT_PATH}/start_x.elf .
    cp ${UBOOT_PATH}/u-boot.bin .

    # RPi firmware loads and modify the DTB before pass it to kernel.
    freebsd_install_fdt rpi2.dts rpi2.dtb

    # Install ubldr to FAT partition
    freebsd_ubldr_copy_ubldr .
}

strategy_add $PHASE_BOOT_INSTALL raspberry_pi_populate_boot_partition

strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir boot/msdos
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_ubldr_copy_ubldr boot
