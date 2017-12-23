KERNCONF=GENERIC
PINE64_UBOOT_PORT="u-boot-pine64"
PINE64_UBOOT_BIN="u-boot-sunxi-with-spl.bin"
PINE64_UBOOT_PATH="/usr/local/share/u-boot/${PINE64_UBOOT_PORT}"
IMAGE_SIZE=$((2000 * 1000 * 1000))
TARGET_ARCH=aarch64
TARGET=aarch64

# Not used - just in case someone wants to use a manual ubldr.  Obtained
# from 'printenv' in boot0: kernel_addr_r=0x42000000
UBLDR_LOADADDR=0x42000000

pine64_check_uboot ( ) {
    uboot_port_test ${PINE64_UBOOT_PORT} ${PINE64_UBOOT_BIN}
}
strategy_add $PHASE_CHECK pine64_check_uboot

#
# Pine64 uses EFI, so the first partition will be a FAT partition.
#
pine64_partition_image ( ) {
    echo "Installing U-Boot from: ${PINE64_UBOOT_PATH}"
    dd if=${PINE64_UBOOT_PATH}/${PINE64_UBOOT_BIN} of=/dev/${DISK_MD} conv=notrunc,sync seek=16
    disk_partition_mbr
    disk_fat_create 64m 16 16384 -
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW pine64_partition_image

pine64_uboot_install ( ) {
    echo bootaa64 > startup.nsh
    mkdir -p EFI/BOOT
}
strategy_add $PHASE_BOOT_INSTALL pine64_uboot_install

# Build & install loader.efi.
strategy_add $PHASE_BUILD_OTHER freebsd_loader_efi_build
strategy_add $PHASE_BOOT_INSTALL freebsd_loader_efi_copy EFI/BOOT/bootaa64.efi

# Pine64 puts the kernel on the FreeBSD UFS partition.
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
# overlay/etc/fstab mounts the FAT partition at /boot/efi
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir -p boot/efi
