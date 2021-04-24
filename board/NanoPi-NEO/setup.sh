KERNCONF=GENERIC
UBLDR_LOADADDR=0x42000000
SUNXI_UBOOT=u-boot-nanopi_neo
SUNXI_UBOOT_BIN=u-boot-sunxi-with-spl.bin
UBOOT_PATH=/usr/local/share/u-boot/${SUNXI_UBOOT}
TARGET_ARCH=armv7
FREEBSD_SRC=/usr/src
FREEBSD_SYS=${FREEBSD_SRC}/sys
IMAGE_SIZE=$((1000 * 1000 * 1000))

allwinner_partition_image() {
	echo "Installing U-Boot from: ${UBOOT_PATH}"

	dd if=${UBOOT_PATH}/${SUNXI_UBOOT_BIN} conv=notrunc,sync of=/dev/${DISK_MD} bs=1024 seek=8

	disk_partition_mbr
	disk_fat_create 32m 16 1m
	disk_ufs_create
}

allwinner_check_uboot() {
	uboot_port_test ${SUNXI_UBOOT} ${SUNXI_UBOOT_BIN}
}

allwinner_scr_build_copy() {
	cat << EOF > ${BOARD_BOOT_MOUNTPOINT}/boot.cmd
echo "Loading U-boot loader: ubldr.bin"
load \${devtype} \${devnum}:\${distro_bootpart} ${UBLDR_LOADADDR} ubldr.bin
go ${UBLDR_LOADADDR}
EOF

	mkimage -A arm -T script -C none -n "Boot Commands" -d ${BOARD_BOOT_MOUNTPOINT}/boot.cmd ${BOARD_BOOT_MOUNTPOINT}/boot.scr
}

strategy_add $PHASE_PARTITION_LWW allwinner_partition_image
strategy_add $PHASE_CHECK allwinner_check_uboot
strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build UBLDR_LOADADDR=${UBLDR_LOADADDR}
strategy_add $PHASE_BOOT_INSTALL freebsd_ubldr_copy_ubldr .

# Put the kernel on the FreeBSD UFS partition.
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .

# boot files go on the msdos partition (after boot dir exists)
strategy_add $PHASE_FREEBSD_BOARD_INSTALL allwinner_scr_build_copy

# ubldr help and config files go on the UFS partition (after boot dir exists)
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_ubldr_copy boot
