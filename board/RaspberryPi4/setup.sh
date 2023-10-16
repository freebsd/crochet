TARGET_ARCH=aarch64
TARGET=aarch64
# ARMv7 32-bit build
#TARGET=arm
#TARGET_ARCH=armv7
KERNCONF=GENERIC
RPI4_UBOOT_PORT="u-boot-rpi4"
RPI4_UBOOT_BIN="u-boot.bin"
RPI4_UBOOT_PATH="${SHARE_PATH}/u-boot/${RPI4_UBOOT_PORT}"
RPI_FIRMWARE_PORT="rpi-firmware"
RPI_FIRMWARE_BIN="bootcode.bin"
RPI_FIRMWARE_PATH="${SHARE_PATH}/${RPI_FIRMWARE_PORT}"
RPI_FIRMWARE_FILES="bootcode.bin \
    fixup4.dat fixup4cd.dat fixup4db.dat fixup4x.dat \
    start4.elf start4cd.elf start4db.elf start4x.elf"
if [ ${TARGET} == "aarch64" ]; then
    RPI_FIRMWARE_FILES="${RPI_FIRMWARE_FILES} armstub8-gic.bin"
fi
IMAGE_SIZE=$((4 * 1000 * 1000 * 1000))

# Not used - just in case someone wants to use a manual ubldr.  Obtained
# from 'printenv' in boot0: kernel_addr_r=0x42000000
#UBLDR_LOADADDR=0x42000000

rpi4_check_uboot ( ) {
    uboot_port_test ${RPI4_UBOOT_PORT} ${RPI4_UBOOT_BIN}
}
strategy_add $PHASE_CHECK rpi4_check_uboot

rpi_check_firmware ( ) {
    firmware_port_test ${RPI_FIRMWARE_PORT} ${RPI_FIRMWARE_BIN}
}
strategy_add $PHASE_CHECK rpi_check_firmware

#
# Rpi4 uses EFI, so the first partition will be a FAT partition.
#
rpi4_partition_image ( ) {
    disk_partition_mbr
    # Use FAT32. rpi4 does not support FAT16.
    disk_fat_create 50m 32 -1 '' 1
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW rpi4_partition_image

raspberry_pi_populate_boot_partition ( ) {
    mkdir -p EFI/BOOT
    for file in ${RPI_FIRMWARE_FILES}; do
        cp ${RPI_FIRMWARE_PATH}/${file} .
    done
    cp ${UBOOT_PATH}/u-boot.bin .
    cp ${UBOOT_PATH}/README .

    # Populate config.txt
    if [ ${TARGET} == "aarch64" ]; then
        cp ${RPI_FIRMWARE_PATH}/config_rpi4.txt config.txt
    else
        cp ${RPI_FIRMWARE_PATH}/config.txt config.txt
        echo "dtoverlay=disable-bt" >> config.txt
    fi

    # Copy in overlays
    cp -R ${RPI_FIRMWARE_PATH}/overlays .

    # Populate DTB
    cp ${RPI_FIRMWARE_PATH}/bcm2711-rpi-4-b.dtb .
}
strategy_add $PHASE_BOOT_INSTALL raspberry_pi_populate_boot_partition

# Build & install loader.efi.
strategy_add $PHASE_BUILD_OTHER freebsd_loader_efi_build
if [ ${TARGET} == "aarch64" ]; then
    strategy_add $PHASE_BOOT_INSTALL freebsd_loader_efi_copy EFI/BOOT/bootaa64.efi
else
    strategy_add $PHASE_BOOT_INSTALL freebsd_loader_efi_copy EFI/BOOT/bootarm.efi
fi

# Rpi4 puts the kernel on the FreeBSD UFS partition.
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
# overlay/etc/fstab mounts the FAT partition at /boot/efi
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir -p boot/efi
