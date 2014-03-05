KERNCONF=ZEDBOARD
TARGET_ARCH=armv6
IMAGE_SIZE=$((1000 * 1000 * 1000))

#
# Support for ZedBoard and possibly other Xilinx Zynq-7000 platforms.
#
# Based on Thomas Skibo's information from
# http://www.thomasskibo.com/zedbsd/
#

# ZedBoard requires a FAT partition to hold the boot loader bits.
zedboard_partition_image ( ) {
    disk_partition_mbr
    disk_fat_create 64m
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW zedboard_partition_image

zedboard_mount_partitions ( ) {
    disk_fat_mount ${BOARD_BOOT_MOUNTPOINT}
    board_ufs_mount_all
}
strategy_add $PHASE_MOUNT_LWW zedboard_mount_partitions

# TODO: Build U-Boot from source.
strategy_add $PHASE_BOOT_INSTALL cp ${BOARDDIR}/bootfiles/* .
strategy_add $PHASE_BOOT_INSTALL gunzip BOOT.BIN.gz

# Build and install ubldr from source
strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build UBLDR_LOADADDR=0x80000
strategy_add $PHASE_BOOT_INSTALL freebsd_ubldr_copy_ubldr ubldr

# Install the FDT files on the boot partition
strategy_add $PHASE_BOOT_INSTALL freebsd_install_fdt arm/zedboard.dts zedboard.dts
strategy_add $PHASE_BOOT_INSTALL freebsd_install_fdt arm/zedboard.dts board.dtb

strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir -p boot/msdos
# ubldr help file goes on the UFS partition (after boot dir is created)
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_ubldr_copy_ubldr_help boot
