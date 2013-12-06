KERNCONF=WANDBOARD-QUAD
TARGET_ARCH=arm
IMAGE_SIZE=$((1024 * 1000 * 1000))
WANDBOARD_UBOOT_SRC=${TOPDIR}/u-boot-2013.10

#
# 2 partitions, a FAT one for the boot and a UFS one
#
# the kernel config (WANDBOARD.common) specifies:
# U-Boot stuff lives on slice 1, FreeBSD on slice 2.
# options         ROOTDEVNAME=\"ufs:mmcsd0s2a\"
#
wandboard_partition_image ( ) {
    disk_partition_mbr
    disk_fat_create 2m
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

wandboard_uboot_install ( ) {
        echo installing 
	dd if=${WANDBOARD_UBOOT_SRC}/u-boot.imx of=${BOARD_BOOT_MOUNTPOINT} bs=1 seek=1024
}

strategy_add $PHASE_BOOT_INSTALL wandboard_uboot_install

strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_installkernel .


