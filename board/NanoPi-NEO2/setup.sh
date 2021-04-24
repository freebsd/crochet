KERNCONF=GENERIC
SUNXI_UBOOT=u-boot-nanopi-neo2
SUNXI_UBOOT_BIN=u-boot-sunxi-with-spl.bin
UBOOT_PATH=/usr/local/share/u-boot/${SUNXI_UBOOT}
TARGET_ARCH=aarch64
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

allwinner_install_uboot() {
	echo bootaa64 > startup.nsh

	mkdir -p EFI/BOOT
}

allwinner_loader_efi_copy() {
	echo "Installing loader.efi in ${TARGET}"

	cp boot/loader.* ${BOARD_BOOT_MOUNTPOINT}
	mv ${BOARD_BOOT_MOUNTPOINT}/loader.efi ${BOARD_BOOT_MOUNTPOINT}/EFI/BOOT/bootaa64.efi
}

strategy_add $PHASE_PARTITION_LWW allwinner_partition_image
strategy_add $PHASE_CHECK allwinner_check_uboot
strategy_add $PHASE_BOOT_INSTALL allwinner_install_uboot

# Put the kernel on the FreeBSD UFS partition.
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .

# loader files go on the msdos partition (after boot dir exists)
strategy_add $PHASE_FREEBSD_BOARD_INSTALL allwinner_loader_efi_copy
