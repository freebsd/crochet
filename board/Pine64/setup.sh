KERNCONF=GENERIC
PINE64_UBOOT_PORT="u-boot-pine64"
PINE64_UBOOT_BIN="pine64.img"
PINE64_UBOOT_PATH="/usr/local/share/u-boot/${PINE64_UBOOT_PORT}"
IMAGE_SIZE=$((1000 * 1000 * 1000))
TARGET_ARCH=aarch64
TARGET=aarch64

pine64_check_uboot ( ) {
    uboot_port_test ${PINE64_UBOOT_PORT} ${PINE64_UBOOT_BIN}
}
strategy_add $PHASE_CHECK pine64_check_uboot

#
# Pine64 requires a FAT partition to hold the boot loader bits.
#
pine64_partition_image ( ) {
    disk_partition_mbr
    disk_fat_create 2m
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW pine64_partition_image

pine64_uboot_install ( ) {
    echo "Installing U-Boot from: ${PINE64_UBOOT_PATH}"
    dd if=${PINE64_UBOOT_PATH}/u-boot.img of=/dev/${DISK_MD} seek=16
    touch uEnv.txt
    freebsd_install_fdt pine64_plus.dts pine64_plus.dts
}
strategy_add $PHASE_BOOT_INSTALL pine64_uboot_install

# Build and install a suitable ubldr
# from 'printenv' in boot0: kernel_addr_r=0x42000000
strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build UBLDR_LOADADDR=0x42000000
strategy_add $PHASE_BOOT_INSTALL freebsd_ubldr_copy_ubldr .

# Pine64 puts the kernel on the FreeBSD UFS partition.
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
# overlay/etc/fstab mounts the FAT partition at /boot/msdos
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir -p boot/msdos
# ubldr help and config files go on the UFS partition (after boot dir exists)
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_ubldr_copy boot
