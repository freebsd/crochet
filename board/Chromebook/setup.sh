KERNCONF=CHROMEBOOK
TARGET_ARCH=armv6
IMAGE_SIZE=$((1024 * 1000 * 1000))
CHROMEBOOK_UBOOT_SRC=${TOPDIR}/u-boot-2014.07

#
# partitions
#
chromebook_partition_image ( ) {
    # disk is gpt
    disk_partition_gpt
    # create ChromeOS partition and put U-Boot on it
    chromebook_uboot_install
    # FreeBSD root
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW chromebook_partition_image

#
# Chromebook uses U-Boot.
#
chromebook_check_uboot ( ) {
    # Crochet needs to build U-Boot.
    uboot_set_patch_version ${CHROMEBOOK_UBOOT_SRC} ${CHROMEBOOK_UBOOT_PATCH_VERSION}

    uboot_test \
        CHROMEBOOK_UBOOT_SRC \
        "$CHROMEBOOK_UBOOT_SRC/board/samsung/smdk5250/Makefile"
    strategy_add $PHASE_BUILD_OTHER uboot_configure $CHROMEBOOK_UBOOT_SRC snow_config
    strategy_add $PHASE_BUILD_OTHER uboot_build $CHROMEBOOK_UBOOT_SRC
}
strategy_add $PHASE_CHECK chromebook_check_uboot

#
# install uboot onto the ChromeOS Kernel parition
#
chromebook_uboot_install ( ) {
    # Add ChromeOS kernel parition
    CHROMEOS_KERNEL_PARTITION=`gpart add -t "!fe3a2a5d-4f32-41a7-b725-accc3285a309" -s 16M -l U-Boot ${DISK_MD} | sed -e 's/ .*//'`
    CHROMEOS_KERNEL_MOUNTPOINT=/dev/${CHROMEOS_KERNEL_PARTITION}
    echo ChromeOS Kernel Mountpoint is ${CHROMEOS_KERNEL_MOUNTPOINT}
    echo Installing U-Boot to ${CHROMEOS_KERNEL_MOUNTPOINT}
    #dd if=${CHROMEBOOK_UBOOT_SRC}/u-boot.bin of=${CHROMEOS_KERNEL_MOUNTPOINT} bs=512
}

#
# ubldr
#
#strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build UBLDR_LOADADDR=0x88000000
#strategy_add $PHASE_BOOT_INSTALL freebsd_ubldr_copy_ubldr ubldr

#
# kernel
#
#strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
#strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_ubldr_copy_ubldr_help boot

#
# Make a /boot/msdos directory so the running image
# can mount the FAT partition.  (See overlay/etc/fstab.)
#
#strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir boot/msdos

#
#  build the u-boot scr file
#
#strategy_add $PHASE_BOOT_INSTALL uboot_mkimage "files/boot.txt" "boot.scr"
