KERNCONF=PANDABOARD
PANDABOARD_UBOOT_SRC=${TOPDIR}/u-boot-2012.07
IMAGE_SIZE=$((1000 * 1000 * 1000))
TARGET_ARCH=arm

#
# PandaBoard uses MBR image with 2mb FAT partition for booting.
#
pandaboard_partition_image ( ) {
    disk_partition_mbr
    disk_fat_create 2m
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW pandaboard_partition_image

pandaboard_mount_partitions ( ) {
    disk_fat_mount ${BOARD_BOOT_MOUNTPOINT}
    disk_ufs_mount ${BOARD_FREEBSD_MOUNTPOINT}
}
strategy_add $PHASE_MOUNT_LWW pandaboard_mount_partitions

#
# PandaBoard uses U-Boot
#
pandaboard_check_prerequisites ( ) {
    uboot_test \
        PANDABOARD_UBOOT_SRC \
        "${PANDABOARD_UBOOT_SRC}/board/ti/panda/Makefile" \
        "fetch ftp://ftp.denx.de/pub/u-boot/u-boot-2012.07.tar.bz2" \
        "tar xf u-boot-2012.07.tar.bz2"
    strategy_add $PHASE_BUILD_OTHER uboot_patch ${PANDABOARD_UBOOT_SRC} ${BOARDDIR}/files/uboot_*.patch
    strategy_add $PHASE_BUILD_OTHER uboot_configure ${PANDABOARD_UBOOT_SRC} omap4_panda
    strategy_add $PHASE_BUILD_OTHER uboot_build ${PANDABOARD_UBOOT_SRC}
}
strategy_add $PHASE_CHECK pandaboard_check_prerequisites

pandaboard_install_uboot ( ) {
    echo "Installing U-Boot onto the boot partition"
    # For now, we use a copy of an MLO built by someone else.
    cp ${BOARDDIR}/boot/MLO ${BOARD_BOOT_MOUNTPOINT}
    # TODO: We should be able to use MLO built by U-Boot. <sigh>
    #
    # As of late 2012, this is broken in the Denx U-Boot sources.
    # Specifically, PandaBoard requires MLO to be under 32k and the
    # default MLO is 38k.  If you'd like to help fix this, try setting
    # CONFIG_SPL_MAX_SIZE in include/configs/omap4_common.h and then
    # see if you can puzzle out how to get it to actually build.
    #
    #cp ${PANDABOARD_UBOOT_SRC}/MLO ${BOARD_BOOT_MOUNTPOINT}
    cp ${PANDABOARD_UBOOT_SRC}/u-boot.bin ${BOARD_BOOT_MOUNTPOINT}
}
strategy_add $PHASE_BOOT_INSTALL pandaboard_install_uboot

#
# PandaBoard uses ubldr
#
strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build UBLDR_LOADADDR=0x88000000
strategy_add $PHASE_BOOT_INSTALL freebsd_ubldr_copy_ubldr ubldr


# BeagleBone puts the kernel on the FreeBSD UFS partition.
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_installkernel .
# ubldr help file goes on the UFS partition (after boot dir exists)
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_ubldr_copy_ubldr_help boot

#
# Make a /boot/msdos directory so the running image
# can mount the FAT partition.  (See overlay/etc/fstab.)
#
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir boot/msdos
