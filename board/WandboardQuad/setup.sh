KERNCONF=WANDBOARD-QUAD
TARGET_ARCH=arm
IMAGE_SIZE=$((1024 * 1000 * 1000))
WANDBOARD_UBOOT_SRC=${TOPDIR}/u-boot-2013.10

#
# Wandboard uses U-Boot.
#
# patches come from here https://raw.github.com/eewiki/u-boot-patches/master/v2013.10/0001-wandboard-uEnv.txt-bootz-n-fixes.patch
#
wandboard_check_uboot ( ) {
        # Crochet needs to build U-Boot.
        uboot_test \
            WANDBOARD_UBOOT_SRC \
            "$WANDBOARD_UBOOT_SRC/board/ti/am335x/Makefile" \
            "ftp ftp://ftp.denx.de/pub/u-boot/u-boot-2013.10.tar.bz2" \
            "tar xf u-boot-2013.10.tar.bz2"
        strategy_add $PHASE_BUILD_OTHER uboot_patch ${WANDBOARD_UBOOT_SRC} ${BOARDDIR}/files/uboot_*.patch
        strategy_add $PHASE_BUILD_OTHER uboot_configure $WANDBOARD_UBOOT_SRC wandboard_quad_config
        strategy_add $PHASE_BUILD_OTHER uboot_build $WANDBOARD_UBOOT_SRC
}
strategy_add $PHASE_CHECK wandboard_check_uboot

# create a MBR disk with a single UFS partition
# based on instructions here: http://www.wonkity.com/~wblock/docs/html/disksetup.html
#
wandboardquad_partition_image ( ) {
        BOOTFILES=${OBJFILES}sys/boot/i386
        echo "Boot files are at: "${BOOTFILES}

        # basic setup
        disk_partition_mbr
        disk_ufs_create

        # boot loader
        echo "Installing bootblocks"
        gpart bootcode -b ${BOOTFILES}/mbr/mbr ${DISK_MD} || exit 1
        gpart set -a active -i 1 ${DISK_MD} || exit 1
        bsdlabel -B -b ${BOOTFILES}/boot2/boot ${DISK_UFS_PARTITION} || exit 1

        #show the disk
        gpart show ${DISK_MD}
}

strategy_add $PHASE_PARTITION_LWW wandboardquad_partition_image

# Kernel installs in UFS partition
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_installkernel .


