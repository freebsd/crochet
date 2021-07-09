# Setup for NanoPi-R4S

KERNCONF=GENERIC

TARGET=arm64
TARGET_ARCH=aarch64

UBOOT_DIR="u-boot-nanopi-r4s"
UBOOT_PATH="/usr/local/share/u-boot/${UBOOT_DIR}"
UBOOT_BIN="u-boot.itb"

nanopi-r4s_check_uboot ( ) {
	uboot_port_test ${UBOOT_DIR} ${UBOOT_BIN}
}
strategy_add $PHASE_CHECK nanopi-r4s_check_uboot

#
# NanoPI-R4S uses EFI, so the first partition will be a FAT partition.
#
nanopi-r4s_partition_image ( ) {
	echo "Installing U-Boot on ${DISK_MD}"
	dd if=${UBOOT_PATH}/idbloader.img of=/dev/${DISK_MD} conv=sync bs=512 seek=64
	dd if=${UBOOT_PATH}/${UBOOT_BIN}  of=/dev/${DISK_MD} conv=sync bs=512 seek=16384

	echo "Installing Partitions on ${DISK_MD}"
	disk_partition_mbr
	disk_fat_create 64m 16 1048576 -
	disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW nanopi-r4s_partition_image

# Build & install loader.efi.
strategy_add $PHASE_BUILD_OTHER  freebsd_loader_efi_build
strategy_add $PHASE_BOOT_INSTALL mkdir -p EFI/BOOT
strategy_add $PHASE_BOOT_INSTALL freebsd_loader_efi_copy EFI/BOOT/bootaa64.efi

# Puts the kernel on the FreeBSD UFS partition.
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
# overlay/etc/fstab mounts the FAT partition at /boot/efi
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir -p boot/efi
