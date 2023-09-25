TARGET_ARCH=aarch64
TARGET=aarch64
#TARGET=arm
#TARGET_ARCH=armv7
KERNCONF=GENERIC
RPI3_UBOOT_PORT="u-boot-rpi3"
RPI3_UBOOT_BIN="u-boot.bin"
RPI3_UBOOT_PATH="${SHARE_PATH}/u-boot/${RPI3_UBOOT_PORT}"
RPI_FIRMWARE_PORT="rpi-firmware"
RPI_FIRMWARE_BIN="bootcode.bin"
RPI_FIRMWARE_PATH="${SHARE_PATH}/${RPI_FIRMWARE_PORT}"
RPI_FIRMWARE_FILES="bootcode.bin \
    fixup.dat fixup_cd.dat fixup_db.dat fixup_x.dat \
    start.elf start_cd.elf start_db.elf start_x.elf"
if [ ${TARGET} == "aarch64" ]; then
    RPI_FIRMWARE_FILES="${RPI_FIRMWARE_FILES} armstub8.bin"
fi
IMAGE_SIZE=$((4 * 1000 * 1000 * 1000))

# Not used - just in case someone wants to use a manual ubldr.  Obtained
# from 'printenv' in boot0: kernel_addr_r=0x42000000
#UBLDR_LOADADDR=0x42000000

rpi3_check_uboot ( ) {
    uboot_port_test ${RPI3_UBOOT_PORT} ${RPI3_UBOOT_BIN}
}
strategy_add $PHASE_CHECK rpi3_check_uboot

rpi_check_firmware ( ) {
    firmware_port_test ${RPI_FIRMWARE_PORT} ${RPI_FIRMWARE_BIN}
}
strategy_add $PHASE_CHECK rpi_check_firmware

#
# RPi3 uses EFI, so the first partition will be a FAT partition.
#
rpi3_partition_image ( ) {
    disk_partition_mbr
    # Use FAT16.  The minimum space requirement for FAT32 is too big for this.
    disk_fat_create 50m 16
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW rpi3_partition_image

raspberry_pi_populate_boot_partition ( ) {
    mkdir -p EFI/BOOT
    for file in ${RPI_FIRMWARE_FILES}; do
        cp ${RPI_FIRMWARE_PATH}/${file} .
    done
    cp ${UBOOT_PATH}/u-boot.bin .
    cp ${UBOOT_PATH}/README .

    # Populate config.txt
    if [ ${TARGET} == "aarch64" ]; then
        cp ${RPI_FIRMWARE_PATH}/config_rpi3.txt config.txt
    else
        cp ${RPI_FIRMWARE_PATH}/config.txt config.txt
        echo "dtoverlay=pi3-disable-bt" >> config.txt
    fi

    # Copy in overlays
    cp -R ${RPI_FIRMWARE_PATH}/overlays .

    # Populate DTB
    cp ${RPI_FIRMWARE_PATH}/bcm2710-rpi-3-b.dtb .
}
strategy_add $PHASE_BOOT_INSTALL raspberry_pi_populate_boot_partition

# Build & install loader.efi.
strategy_add $PHASE_BUILD_OTHER freebsd_loader_efi_build
if [ ${TARGET} == "aarch64" ]; then
    strategy_add $PHASE_BOOT_INSTALL freebsd_loader_efi_copy EFI/BOOT/bootaa64.efi
else
    strategy_add $PHASE_BOOT_INSTALL freebsd_loader_efi_copy EFI/BOOT/bootarm.efi
fi

# RPi3 puts the kernel on the FreeBSD UFS partition.
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
# overlay/etc/fstab mounts the FAT partition at /boot/efi
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir -p boot/efi
