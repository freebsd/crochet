KERNCONF=GENERIC
BEAGLEBONE_UBOOT_PORT="u-boot-beaglebone"
BEAGLEBONE_UBOOT_BIN="u-boot.img"
BEAGLEBONE_UBOOT_PATH="/usr/local/share/u-boot/${BEAGLEBONE_UBOOT_PORT}"
IMAGE_SIZE=$((1000 * 1000 * 1000))
TARGET_ARCH=armv6

beaglebone_check_uboot ( ) {
    uboot_port_test ${BEAGLEBONE_UBOOT_PORT} ${BEAGLEBONE_UBOOT_BIN}
}
strategy_add $PHASE_CHECK beaglebone_check_uboot

#
# BeagleBone requires a FAT partition to hold the boot loader bits.
#
beaglebone_partition_image ( ) {
    disk_partition_mbr
    disk_fat_create 32m 16
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW beaglebone_partition_image

beaglebone_uboot_install ( ) {
    echo "Installing U-Boot from: ${BEAGLEBONE_UBOOT_PATH}"
    cp ${BEAGLEBONE_UBOOT_PATH}/MLO .
    cp ${BEAGLEBONE_UBOOT_PATH}/u-boot.img .
    touch uEnv.txt
    freebsd_install_fdt beaglebone.dts bbone.dts
    freebsd_install_fdt beaglebone.dts bbone.dtb
    freebsd_install_fdt beaglebone-black.dts bboneblk.dts
    freebsd_install_fdt beaglebone-black.dts bboneblk.dtb
}
strategy_add $PHASE_BOOT_INSTALL beaglebone_uboot_install

# Build and install a suitable ubldr
strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build UBLDR_LOADADDR=0x88000000
strategy_add $PHASE_BOOT_INSTALL freebsd_ubldr_copy_ubldr .

# BeagleBone puts the kernel on the FreeBSD UFS partition.
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
# overlay/etc/fstab mounts the FAT partition at /boot/msdos
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir -p boot/msdos
# ubldr help and config files go on the UFS partition (after boot dir exists)
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_ubldr_copy boot
