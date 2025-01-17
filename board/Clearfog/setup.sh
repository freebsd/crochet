KERNCONF=GENERIC
TARGET_ARCH=armv7
IMAGE_SIZE=$((2 * 1000 * 1000 * 1000))

# check for mkimage utility
clearfog_check_uboot-tools ( ) {
    if [ -z `which mkimage` ]; then
        echo "Clearfog Boot-Script build requires 'mkimage'"
        echo "Please install sysutils/u-boot-tools and re-run this script."
        exit 1
    fi
}
strategy_add $PHASE_CHECK clearfog_check_uboot-tools

# build ubldr
strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build

# partition disk
# 1: reserved space for u-boot (first 1M into the device)
# 2: boot
# 3: FreeBSD
clearfog_disk_reserved_create_unaligned ( ) {
    _DISK_RESERVED_SLICE=`gpart add -s $1 -t '!218' ${DISK_MD} | sed -e 's/ .*//'`
    disk_created_new RESERVED ${_DISK_RESERVED_SLICE}
}
clearfog_partition_image ( ) {
    disk_partition_mbr
    clearfog_disk_reserved_create_unaligned 1985
    disk_fat_create 2m
    disk_ufs_create
    disk_ufs_label 1 rootfs
}
strategy_add $PHASE_PARTITION_LWW clearfog_partition_image

# install boot files
clearfog_install_boot-files ( ) {
    freebsd_ubldr_copy_ubldr ${BOARD_BOOT_MOUNTPOINT}
    mkimage -A arm -O FreeBSD -T script -a 0 -e 0 -d "$BOARDDIR/files/boot.txt" "boot.scr" > ${WORKDIR}/_.mkimage.log
    freebsd_install_fdt ../gnu/dts/arm/armada-388-clearfog-base.dts armada-388-clearfog-base.dtb
    freebsd_install_fdt ../gnu/dts/arm/armada-388-clearfog-pro.dts armada-388-clearfog-pro.dtb

    # out of tree DTBs
    ln -sv "$BOARDDIR/files/armada-388-helios4.dts" "$FREEBSD_SRC/sys/gnu/dts/arm/armada-388-helios4.dts"
    freebsd_install_fdt ../gnu/dts/arm/armada-388-helios4.dts armada-388-helios4.dtb
    rm -f "$FREEBSD_SRC/sys/gnu/dts/arm/armada-388-helios4.dts"
}
strategy_add $PHASE_BOOT_INSTALL clearfog_install_boot-files

# install kernel on rootfs
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .

# install ubldr help and configuration to rootfs
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_ubldr_copy boot

# create mount-point for boot partition
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir -p boot/msdos
