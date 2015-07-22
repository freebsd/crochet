KERNCONF=IMX6
TARGET_ARCH=armv6
IMAGE_SIZE=$((1024 * 1000 * 1000))
WANDBOARD_UBOOT_SRC=${TOPDIR}/u-boot-2014.07

#
# 3 partitions, a reserve one for uboot, a FAT one for the boot loader and a UFS one
#
# the kernel config (WANDBOARD.common) specifies:
# U-Boot stuff lives on slice 1, FreeBSD on slice 2.
# options         ROOTDEVNAME=\"ufs:mmcsd0s2a\"
#
wandboard_partition_image ( ) {
    disk_partition_mbr
    wandboard_uboot_install
    disk_fat_create 50m 16 16384
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW wandboard_partition_image

#
# Wandboard uses U-Boot.
#
wandboard_check_uboot ( ) {
	# Crochet needs to build U-Boot.

    uboot_set_patch_version ${WANDBOARD_UBOOT_SRC} ${WANDBOARD_UBOOT_PATCH_VERSION}

    uboot_test \
        WANDBOARD_UBOOT_SRC \
        "$WANDBOARD_UBOOT_SRC/board/wandboard/Makefile"
    strategy_add $PHASE_BUILD_OTHER uboot_patch ${WANDBOARD_UBOOT_SRC} `uboot_patch_files`
    strategy_add $PHASE_BUILD_OTHER uboot_configure $WANDBOARD_UBOOT_SRC wandboard_quad_config
    strategy_add $PHASE_BUILD_OTHER uboot_build $WANDBOARD_UBOOT_SRC
}
strategy_add $PHASE_CHECK wandboard_check_uboot

#
# install uboot
#
wandboard_uboot_install ( ) {
    echo Installing U-Boot to /dev/${DISK_MD}
    dd if=${WANDBOARD_UBOOT_SRC}/u-boot.imx of=/dev/${DISK_MD} bs=512 seek=2
}

#
# ubldr
#
strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build UBLDR_LOADADDR=0x11000000
strategy_add $PHASE_BOOT_INSTALL freebsd_ubldr_copy_ubldr .

#
# uEnv
#
wandboard_install_uenvtxt(){
    echo "Installing uEnv.txt"
    cp ${BOARDDIR}/files/uEnv.txt .
}
#strategy_add $PHASE_BOOT_INSTALL wandboard_install_uenvtxt

#
# DTS to FAT file system
#
wandboard_install_dts_fat(){
    echo "Installing DTS to FAT"
    freebsd_install_fdt wandboard-quad.dts wandboard-quad.dts
    freebsd_install_fdt wandboard-quad.dts wandboard-quad.dtb
}
#strategy_add $PHASE_BOOT_INSTALL wandboard_install_dts_fat

#
# DTS to UFS file system. This is in PHASE_FREEBSD_BOARD_POST_INSTALL b/c it needs to happen *after* the kernel install
#
wandboard_install_dts_ufs(){
    echo "Installing DTS to UFS"
    freebsd_install_fdt wandboard-quad.dts boot/kernel/wandboard-quad.dts
    freebsd_install_fdt wandboard-quad.dts boot/kernel/wandboard-quad.dtb
}
strategy_add $PHASE_FREEBSD_BOARD_POST_INSTALL wandboard_install_dts_ufs

#
# kernel
#
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_ubldr_copy_ubldr_help boot

#
# Make a /boot/msdos directory so the running image
# can mount the FAT partition.  (See overlay/etc/fstab.)
#
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir boot/msdos

#
#  build the u-boot scr file
#
strategy_add $PHASE_BOOT_INSTALL uboot_mkimage ${WANDBOARD_UBOOT_SRC} "files/boot.txt" "boot.scr"

