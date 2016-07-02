KERNCONF=GENERIC
PINE64_UBOOT_PORT="u-boot-pine64"
PINE64_UBOOT_BIN="pine64.img"
PINE64_UBOOT_PATH="/usr/local/share/u-boot/${PINE64_UBOOT_PORT}"
IMAGE_SIZE=$((1000 * 1000 * 1000))
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
# Pine64 requires a FAT partition to hold the boot loader bits.
#
pine64_partition_image ( ) {
    echo "Installing U-Boot from: ${PINE64_UBOOT_PATH}"
    dd if=${PINE64_UBOOT_PATH}/${PINE64_UBOOT_BIN} of=/dev/${DISK_MD} seek=16
    disk_partition_mbr
    disk_fat_create 2m
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW pine64_partition_image

pine64_uboot_install ( ) {
    touch uEnv.txt
    freebsd_install_fdt arm/pine64_plus.dts pine64_plus.dts
}
strategy_add $PHASE_BOOT_INSTALL pine64_uboot_install

# Build & install loader.efi.
strategy_add $PHASE_BUILD_OTHER freebsd_loader_efi_build
strategy_add $PHASE_BOOT_INSTALL freebsd_loader_efi_copy .

# Pine64 puts the kernel on the FreeBSD UFS partition.
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
# overlay/etc/fstab mounts the FAT partition at /boot/msdos
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir -p boot/msdos
