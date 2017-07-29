KERNCONF=GENERIC
UBLDR_LOADADDR=0x42000000
SUNXI_UBOOT="u-boot-orangepi-plus-2e"
SUNXI_UBOOT_BIN="u-boot.img"
IMAGE_SIZE=$((1000 * 1000 * 1000))
TARGET_ARCH=armv6

UBOOT_PATH="/usr/local/share/u-boot/${SUNXI_UBOOT}"

allwinner_partition_image ( ) {
    echo "Installing U-Boot files"
    dd if=${UBOOT_PATH}/u-boot-sunxi-with-spl.bin conv=notrunc,sync of=/dev/${DISK_MD} bs=1024 seek=8
    dd if=${UBOOT_PATH}/u-boot.img conv=notrunc,sync of=/dev/${DISK_MD} \
	bs=1024 seek=40
    disk_partition_mbr
    disk_fat_create 32m 16 1m
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW allwinner_partition_image

allwinner_check_uboot ( ) {
    uboot_port_test ${SUNXI_UBOOT} ${SUNXI_UBOOT_BIN}
}
strategy_add $PHASE_CHECK allwinner_check_uboot

strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build UBLDR_LOADADDR=${UBLDR_LOADADDR}
strategy_add $PHASE_BOOT_INSTALL freebsd_ubldr_copy_ubldr .

# BeagleBone puts the kernel on the FreeBSD UFS partition.
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
# overlay/etc/fstab mounts the FAT partition at /boot/msdos
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir -p boot/msdos
# ubldr help and config files go on the UFS partition (after boot dir exists)
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_ubldr_copy boot
