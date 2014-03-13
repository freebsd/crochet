KERNCONF=BEAGLEBONE
BEAGLEBONE_UBOOT_SRC=${TOPDIR}/u-boot-2013.04
IMAGE_SIZE=$((1000 * 1000 * 1000))
TARGET_ARCH=armv6

#
# BeagleBone requires a FAT partition to hold the boot loader bits.
#
beaglebone_partition_image ( ) {
    disk_partition_mbr
    disk_fat_create 2m
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW beaglebone_partition_image

#
# BeagleBone uses U-Boot.
#
beaglebone_check_uboot ( ) {
    if [ -n "${BEAGLEBONE_UBOOT_PATCH_VERSION}" -a -n `uboot_eabi_port` ]; then
        echo "Using U-Boot from port: "`u_boot_eabi_port`
    else
        echo
        echo "Please consider installing sysutils/u-boot-beaglebone-eabi port."
        echo "That will avoid the need for Crochet to build U-Boot."
        echo
        # Crochet needs to build U-Boot.

	uboot_set_patch_version ${BEAGLEBONE_UBOOT_SRC} ${BEAGLEBONE_UBOOT_PATCH_VERSION}

        uboot_test \
            BEAGLEBONE_UBOOT_SRC \
            "$BEAGLEBONE_UBOOT_SRC/board/ti/am335x/Makefile"
        strategy_add $PHASE_BUILD_OTHER uboot_patch ${BEAGLEBONE_UBOOT_SRC} `uboot_patch_files`
        strategy_add $PHASE_BUILD_OTHER uboot_configure $BEAGLEBONE_UBOOT_SRC am335x_evm_config
        strategy_add $PHASE_BUILD_OTHER uboot_build $BEAGLEBONE_UBOOT_SRC
    fi

}
strategy_add $PHASE_CHECK beaglebone_check_uboot


beaglebone_uboot_install ( ) {
    if [ -n "${BEAGLEBONE_UBOOT_PATCH_VERSION}" -a -n `uboot_eabi_port` ]; then
        echo "Installing U-Boot from port: "`uboot_eabi_port`
        u-boot-beaglebone-eabi-install .
    else
        echo "Installing U-Boot onto the FAT partition"
        # Note that all of the BeagleBone boot files
        # start with 'BB' now (except for MLO, which can't
        # be renamed because it's loaded by the ROM).
        cp ${BEAGLEBONE_UBOOT_SRC}/MLO .
        cp ${BEAGLEBONE_UBOOT_SRC}/u-boot.img bb-uboot.img
        cp ${BOARDDIR}/files/uEnv.txt bb-uEnv.txt
    fi
    freebsd_install_fdt beaglebone.dts bbone.dts
    freebsd_install_fdt beaglebone.dts bbone.dtb
    freebsd_install_fdt beaglebone-black.dts bboneblk.dts
    freebsd_install_fdt beaglebone-black.dts bboneblk.dtb
}
strategy_add $PHASE_BOOT_INSTALL beaglebone_uboot_install

# TODO: Try changing ubldr to a PIC binary instead of ELF, so we don't
# have to compile it separately for every different load address.
#
strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build UBLDR_LOADADDR=0x88000000
strategy_add $PHASE_BOOT_INSTALL freebsd_ubldr_copy_ubldr bbubldr

# BeagleBone puts the kernel on the FreeBSD UFS partition.
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
# overlay/etc/fstab mounts the FAT partition at /boot/msdos
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir -p boot/msdos
# ubldr help and config files go on the UFS partition (after boot dir exists)
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_ubldr_copy boot
