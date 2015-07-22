KERNCONF=CHROMEBOOK-SNOW
TARGET_ARCH=armv6
FIT_IMAGE=uboot-fit.uimage

# This must be the exact size, in bytes, of the SDHC card
IMAGE_SIZE=8010072064
CHROMEBOOK_UBOOT_SRC=${TOPDIR}/u-boot-2014.07

#
# partitions
#
chromebook_partition_image ( ) {
    # disk is gpt
    disk_partition_gpt
    # create ChromeOS partition and put U-Boot on it
 #   chromebook_make_fit
    chromebook_uboot_install
    # FAT partition
    gpt_add_fat_partition 50m
    # FreeBSD root
    gpt_add_ufs_partition
    # show
    gpart show ${DISK_MD}
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
# install kernel
#
chromebook_kernel_install ( ) {
    `cp ${WORKDIR}/obj/arm.armv6/storage/home/tom/crochet/src/FreeBSDHead/head/sys/CHROMEBOOK-SNOW/kernel.bin .`
#    cd ${FREEBSD_SRC}/
#    `echo pwd` 

 #   `cp ${FREEBSD_OBJDIR}sys/CHROMEBOOK-SNOW/kernel.bin .`
}
strategy_add $PHASE_BOOT_INSTALL chromebook_kernel_install .

#
# make the fit image
#
chromebook_make_fit ( ) {
    TEXT_START=$(grep CONFIG_SYS_TEXT_BASE ${CHROMEBOOK_UBOOT_SRC}/include/configs/exynos5250-dt.h | awk '{ print $3 }')
    (cd $CHROMEBOOK_UBOOT_SRC;tools/mkimage -A arm -O linux -T kernel -C none -a "${TEXT_START}" -e "${TEXT_START}" -n "u-boot" -d u-boot-dtb.bin ${WORKDIR}/${FIT_IMAGE})
}

#
# install uboot onto the ChromeOS Kernel parition
#
chromebook_uboot_install ( ) {
    echo Creating ChromeOS Kernel partition
    # Add ChromeOS kernel parition
    local CHROMEOS_KERNEL_PARTITION=`gpart add -b 1m -s 15m -t '!fe3a2a5d-4f32-41a7-b725-accc3285a309' /dev/${DISK_MD} | sed -e 's/ .*//'`
    local CHROMEOS_KERNEL_MOUNTPOINT=/dev/${CHROMEOS_KERNEL_PARTITION}
    echo ChromeOS Kernel Mountpoint is ${CHROMEOS_KERNEL_MOUNTPOINT}
    echo Installing U-Boot to ${CHROMEOS_KERNEL_MOUNTPOINT}
    echo U-boot image is ${WORKDIR}/${FIT_IMAGE}
#    `dd if=${CHROMEBOOK_UBOOT_SRC}/u-boot.bin of=${CHROMEOS_KERNEL_MOUNTPOINT} bs=1m conv=sync`
    `dd if=board/Chromebook/uboot/nv_uboot-snow-simplefb.kpart of=${CHROMEOS_KERNEL_MOUNTPOINT} bs=1m conv=sync`
#    dd if=${WORKDIR}/${FIT_IMAGE} of=${CHROMEOS_KERNEL_MOUNTPOINT} bs=1m conv=sync`
}

#
# ubldr
#
strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build UBLDR_LOADADDR=0x88000000
strategy_add $PHASE_BOOT_INSTALL freebsd_ubldr_copy_ubldr .

#
# Make a /boot/msdos directory so the running image
# can mount the FAT partition.  (See overlay/etc/fstab.)
#
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir boot/msdos

#
#  build the u-boot scr file
#
strategy_add $PHASE_BOOT_INSTALL uboot_mkimage ${CHROMEBOOK_UBOOT_SRC} "files/boot.txt" "boot.scr"
