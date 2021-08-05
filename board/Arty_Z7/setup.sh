#
# Support for Digilent's Arty Z7 board.
#
# Based on Thomas Skibo's information from
# http://www.thomasskibo.com/zedbsd/
#
# modifcations to support EFI booting on the ARTYZ7 board
# Christopher R. Bowman
# <my_initials>@ChrisBowman.com

KERNCONF=ARTY_Z7
ZYNQ_UBOOT_PORT="u-boot-artyz7"
ZYNQ_UBOOT_BIN="u-boot.img"
ZYNQ_UBOOT_PATH="/usr/local/share/u-boot/${ZYNQ_UBOOT_PORT}"
ZYNQ_DT_BASENAME=artyz7
IMAGE_SIZE=$((1280 * 1024 * 1024))	# 1.2 GB default
TARGET_ARCH=armv6

zynq_check_uboot ( ) {
    uboot_port_test ${ZYNQ_UBOOT_PORT} ${ZYNQ_UBOOT_BIN}
}
strategy_add $PHASE_CHECK zynq_check_uboot

# Tweak image name to distinguish from Zedboard.  (Arty_Z7 uses Zedboard's
# kernel conf file.)
arty_z7_tweak_image_name(){
	IMG=${WORKDIR}/FreeBSD-${TARGET_ARCH}-${FREEBSD_VERSION}-ARTY_Z7-${SOURCE_VERSION}.img
}
strategy_add $PHASE_POST_CONFIG arty_z7_tweak_image_name

# ArtyZ7 requires a FAT partition to hold the boot loader bits.
arty_z7_partition_image ( ) {
    disk_partition_mbr
    disk_fat_create 64m 16 -1 -
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW arty_z7_partition_image

arty_z7_populate_boot_partition ( ) {
    # u-boot files
    cp ${ZYNQ_UBOOT_PATH}/boot.bin .
    cp ${ZYNQ_UBOOT_PATH}/u-boot.img .
    # CRB
    # cp ${ZYNQ_UBOOT_PATH}/uEnv.txt .
    # now using EFI style booting
    echo "fdtfile=artyz7.dtb " > uEnv.txt
    
    mkdir -p EFI/BOOT
    cp ${WORKDIR}/obj/u1/FreeBSD/src/12.0/arm.armv6/stand/efi/boot1/boot1.efi EFI/BOOT/bootarm.efi
    # install the dtb file on the msdos partition
    freebsd_install_fdt ${ZYNQ_DT_BASENAME}.dts ${ZYNQ_DT_BASENAME}.dtb

    # ubldr
    # CRB
    # using EFI boot so don't need ubldr
    # freebsd_ubldr_copy_ubldr .
}

strategy_add $PHASE_BOOT_INSTALL arty_z7_populate_boot_partition

arty_z7_install_dts_ufs(){
    echo "Installing DTS to UFS"
    echo "first freebsd_install_fdt"
    freebsd_install_fdt $ZYNQ_DT_BASENAME.dts boot/kernel/$ZYNQ_DT_BASENAME.dts
    echo "second freebsd_install_fdt"
    freebsd_install_fdt $ZYNQ_DT_BASENAME.dts boot/kernel/board.dtb
    echo "end DTS to UFS"
}
strategy_add $PHASE_FREEBSD_BOARD_POST_INSTALL arty_z7_install_dts_ufs

# Build and install ubldr from source
# strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build

strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir -p boot/msdos

# ubldr help file goes on the UFS partition (after boot dir is created)
# strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_ubldr_copy_ubldr_help boot
