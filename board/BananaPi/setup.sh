KERNCONF=GENERIC
UBLDR_LOADADDR=0x42000000
SUNXI_UBOOT="u-boot-bananapi"
SUNXI_UBOOT_BIN="u-boot-sunxi-with-spl.bin"
IMAGE_SIZE=$((1900 * 1000 * 1000)) # 1.9 GB
TARGET_ARCH=armv7

UBOOT_PATH="/usr/local/share/u-boot/${SUNXI_UBOOT}"

allwinner_partition_image ( ) {
    echo "Installing U-Boot files"
    dd if=${UBOOT_PATH}/${SUNXI_UBOOT_BIN} conv=notrunc,sync of=/dev/${DISK_MD} bs=1024 seek=8
    disk_partition_mbr
    disk_fat_create 32m 16 1m
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW allwinner_partition_image

allwinner_check_uboot ( ) {
    uboot_port_test ${SUNXI_UBOOT} ${SUNXI_UBOOT_BIN}
}

allwinner_install_boot_script () {
	# Install boot_script to boot partition
	echo "Installing u-boot-script"
    cp ${UBOOT_PATH}/boot.scr ./boot.scr.uimg || exit 1
}

strategy_add $PHASE_CHECK allwinner_check_uboot

strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build UBLDR_LOADADDR=${UBLDR_LOADADDR}
strategy_add $PHASE_BOOT_START allwinner_install_boot_script  
strategy_add $PHASE_BOOT_INSTALL freebsd_ubldr_copy_ubldr .

# Put the kernel on the FreeBSD UFS partition.
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
# overlay/etc/fstab mounts the FAT partition at /boot/msdos
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir -p boot/msdos
# ubldr help and config files go on the UFS partition (after boot dir exists)
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_ubldr_copy boot
