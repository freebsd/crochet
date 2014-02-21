KERNCONF=WANDBOARD-QUAD
TARGET_ARCH=armv6
IMAGE_SIZE=$((1024 * 1000 * 1000))
WANDBOARD_UBOOT_SRC=${TOPDIR}/u-boot-2013.10

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
    disk_fat_create 50m 32 16384
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW wandboard_partition_image

wandboard_partition_image_mount_partitions ( ) {
    disk_fat_mount ${BOARD_BOOT_MOUNTPOINT}
    disk_ufs_mount ${BOARD_FREEBSD_MOUNTPOINT}
}
strategy_add $PHASE_MOUNT_LWW wandboard_partition_image_mount_partitions

#
# Wandboard uses U-Boot.
#
# patches come from here 
#
# https://raw.github.com/eewiki/u-boot-patches/master/v2013.10/0001-wandboard-uEnv.txt-bootz-n-fixes.patch
# https://raw.github.com/eewiki/u-boot-patches/master/v2013.10/0001-ARM-mx6-Update-non-Freescale-boards-to-include-CPU-e.patch
#
wandboard_check_uboot ( ) {
	# Crochet needs to build U-Boot.
        uboot_test \
            WANDBOARD_UBOOT_SRC \
            "$WANDBOARD_UBOOT_SRC/board/wandboard/Makefile" \
            "ftp ftp://ftp.denx.de/pub/u-boot/u-boot-2013.10.tar.bz2" \
            "tar xf u-boot-2013.10.tar.bz2"
        strategy_add $PHASE_BUILD_OTHER uboot_patch ${WANDBOARD_UBOOT_SRC} ${BOARDDIR}/files/*.patch
        strategy_add $PHASE_BUILD_OTHER uboot_configure $WANDBOARD_UBOOT_SRC wandboard_quad_config
        strategy_add $PHASE_BUILD_OTHER uboot_build $WANDBOARD_UBOOT_SRC
}
strategy_add $PHASE_CHECK wandboard_check_uboot

#
# install uboot
#
wandboard_uboot_install ( ) {
        echo Installing U-Boot to /dev/${DISK_MD}
        sudo dd if=${WANDBOARD_UBOOT_SRC}/u-boot.imx of=/dev/${DISK_MD} bs=512 seek=2
}

#
# ubldr
#
strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build UBLDR_LOADADDR=0x88000000
strategy_add $PHASE_BOOT_INSTALL freebsd_ubldr_copy_ubldr ubldr

#
# uEnv
#
wandboard_install_uenvtxt(){
    echo "Installing uEnv.txt"
    cp ${BOARDDIR}/files/uEnv.txt .
}
strategy_add $PHASE_BOOT_INSTALL wandboard_install_uenvtxt

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


