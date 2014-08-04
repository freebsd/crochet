KERNCONF=CHROMEBOOK
TARGET_ARCH=armv6
IMAGE_SIZE=$((1024 * 1000 * 1000))
CHROMEBOOK_UBOOT_SRC=${TOPDIR}/u-boot-2014.07

#
# 3 partitions, a reserve one for uboot, a FAT one for the boot loader and a UFS one
#
# the kernel config (WANDBOARD.common) specifies:
# U-Boot stuff lives on slice 1, FreeBSD on slice 2.
# options         ROOTDEVNAME=\"ufs:mmcsd0s2a\"
#
chromebook_partition_image ( ) {
    disk_partition_mbr
    wandboard_uboot_install
    disk_fat_create 50m 16 16384
    disk_ufs_create
}
#strategy_add $PHASE_PARTITION_LWW chromebook_partition_image

#
# Chromebook uses U-Boot.
#
chromebook_check_uboot ( ) {
	# Crochet needs to build U-Boot.

    	uboot_set_patch_version ${WANDBOARD_UBOOT_SRC} ${WANDBOARD_UBOOT_PATCH_VERSION}

        uboot_test \
            CHROMEBOOK_UBOOT_SRC \
            "$CHROMEBOOK_UBOOT_SRC/board/samsung/smdk5250/Makefile"
        strategy_add $PHASE_BUILD_OTHER uboot_configure $CHROMEBOOK_UBOOT_SRC snow_config
        strategy_add $PHASE_BUILD_OTHER uboot_build $CHROMEBOOK_UBOOT_SRC
}
strategy_add $PHASE_CHECK chromebook_check_uboot

#
# install uboot
#
chromebook_uboot_install ( ) {
        echo Installing U-Boot to /dev/${DISK_MD}
        dd if=${WANDBOARD_UBOOT_SRC}/u-boot.imx of=/dev/${DISK_MD} bs=512 seek=2
}

#
# ubldr
#
strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build UBLDR_LOADADDR=0x88000000
strategy_add $PHASE_BOOT_INSTALL freebsd_ubldr_copy_ubldr ubldr

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
strategy_add $PHASE_BOOT_INSTALL uboot_mkimage "files/boot.txt" "boot.scr"

