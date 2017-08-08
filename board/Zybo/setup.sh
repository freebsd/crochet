#
# Support for Digilent's Zybo board.
#
# Based on Thomas Skibo's information from
# http://www.thomasskibo.com/zedbsd/
#

KERNCONF=ZEDBOARD
ZYNQ_UBOOT_PORT="u-boot-zybo"
ZYNQ_UBOOT_BIN="u-boot.img"
ZYNQ_UBOOT_PATH="/usr/local/share/u-boot/${ZYNQ_UBOOT_PORT}"
ZYNQ_DT_BASENAME=zybo
IMAGE_SIZE=$((1280 * 1024 * 1024))	# 1.2 GB default
TARGET_ARCH=armv6

zynq_check_uboot ( ) {
    uboot_port_test ${ZYNQ_UBOOT_PORT} ${ZYNQ_UBOOT_BIN}
}
strategy_add $PHASE_CHECK zynq_check_uboot

# Tweak image name to distinguish from Zedboard.  (Zybo uses Zedboard's
# kernel conf file.)
zybo_tweak_image_name(){
	IMG=${WORKDIR}/FreeBSD-${TARGET_ARCH}-${FREEBSD_VERSION}-ZYBO-${SOURCE_VERSION}.img
}
strategy_add $PHASE_POST_CONFIG zybo_tweak_image_name

# Zubo requires a FAT partition to hold the boot loader bits.
zybo_partition_image ( ) {
    disk_partition_mbr
    disk_fat_create 64m 16 -1 -
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW zybo_partition_image

zybo_populate_boot_partition ( ) {
    # u-boot files
    cp ${ZYNQ_UBOOT_PATH}/boot.bin .
    cp ${ZYNQ_UBOOT_PATH}/u-boot.img .
    cp ${ZYNQ_UBOOT_PATH}/uEnv.txt .

    # ubldr
    freebsd_ubldr_copy_ubldr .
}
strategy_add $PHASE_BOOT_INSTALL zybo_populate_boot_partition

zybo_install_dts_ufs(){
    echo "Installing DTS to UFS"
    freebsd_install_fdt $ZYNQ_DT_BASENAME.dts boot/kernel/$ZYNQ_DT_BASENAME.dts
    freebsd_install_fdt $ZYNQ_DT_BASENAME.dts boot/kernel/board.dtb
}
strategy_add $PHASE_FREEBSD_BOARD_POST_INSTALL zybo_install_dts_ufs

# Build and install ubldr from source
strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build

strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir -p boot/msdos

# ubldr help file goes on the UFS partition (after boot dir is created)
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_ubldr_copy_ubldr_help boot
