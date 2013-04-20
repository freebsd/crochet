KERNCONF=ZEDBOARD
TARGET_ARCH=armv6
IMAGE_SIZE=$((1000 * 1000 * 1000))

#
# Support for ZedBoard and possibly other Xilinx Zynq-7000 platforms.
#
# Based on Thomas Skibo's information from
# http://www.thomasskibo.com/zedbsd/
#
# Untested, since I don't have a ZedBoard.
#

strategy_add $PHASE_CHECK freebsd_current_test

# ZedBoard requires a FAT partition to hold the boot loader bits.
zedboard_partition_image ( ) {
    disk_partition_mbr
    disk_fat_create 64m
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW zedboard_partition_image

zedboard_mount_partitions ( ) {
    disk_fat_mount ${BOARD_BOOT_MOUNTPOINT}
    disk_ufs_mount ${BOARD_FREEBSD_MOUNTPOINT}
}
strategy_add $PHASE_MOUNT_LWW zedboard_mount_partitions

# TODO: We should build ubldr from source (see below)
# TODO: Can other bits here be built from source?
strategy_add $PHASE_BOOT_INSTALL cp ${BOARDDIR}/bootfiles/* .

# TODO: Build and install ubldr from source
#strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build UBLDR_LOADADDR=0x88000000
#strategy_add $PHASE_BOOT_INSTALL freebsd_ubldr_copy_ubldr ubldr

# ubldr help file goes on the UFS partition.
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_ubldr_copy_ubldr_help boot

strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_installkernel .
