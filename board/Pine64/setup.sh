KERNCONF=GENERIC
PINE64_UBOOT_PORT="u-boot-pine64"
PINE64_UBOOT_BIN="u-boot.img"
PINE64_UBOOT_PATH="/usr/local/share/u-boot/${PINE64_UBOOT_PORT}"
IMAGE_SIZE=$((1000 * 1000 * 1000))
TARGET_ARCH=arm64

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
    cp ${PINE64_UBOOT_PATH}/MLO .
    cp ${PINE64_UBOOT_PATH}/u-boot.img .
    touch uEnv.txt
    freebsd_install_fdt pine64.dts bbone.dts
    freebsd_install_fdt pine64.dts bbone.dtb
    freebsd_install_fdt pine64-black.dts bboneblk.dts
    freebsd_install_fdt pine64-black.dts bboneblk.dtb
}
strategy_add $PHASE_BOOT_INSTALL pine64_uboot_install

# Build and install a suitable ubldr
strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build UBLDR_LOADADDR=0x88000000
strategy_add $PHASE_BOOT_INSTALL freebsd_ubldr_copy_ubldr .

# Pine64 puts the kernel on the FreeBSD UFS partition.
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
# overlay/etc/fstab mounts the FAT partition at /boot/msdos
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir -p boot/msdos
# ubldr help and config files go on the UFS partition (after boot dir exists)
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_ubldr_copy boot
