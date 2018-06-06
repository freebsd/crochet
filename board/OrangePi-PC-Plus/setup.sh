KERNCONF=GENERIC
UBLDR_LOADADDR=0x42000000
SUNXI_UBOOT="u-boot-orangepi-pc-plus"
SUNXI_UBOOT_BIN="u-boot.img"
# image size fits a 2+ GB root image in first UFS partition
IMAGE_SIZE=$((3 * 1000 * 1000 * 1000))
TARGET_ARCH=armv7

FREEBSD_SRC=/usr/src
# BOARD_BOOT_MOUNTPOINT
# BOARD_FREEBSD_MOUNTPOINT
# BOARD_CURRENT_MOUNTPOINT

UBOOT_PATH="/usr/local/share/u-boot/${SUNXI_UBOOT}"

allwinner_partition_image ( ) {
    echo "Installing U-Boot files"
    dd if=${UBOOT_PATH}/u-boot-sunxi-with-spl.bin conv=notrunc,sync \
       of=/dev/${DISK_MD} bs=1024 seek=8
    dd if=${UBOOT_PATH}/u-boot.img conv=notrunc,sync \
       of=/dev/${DISK_MD} bs=1024 seek=40
    disk_partition_mbr
    disk_fat_create 32m 16 1m
    # note: /usr/{local,ports} elsewhere - 2.5g for base
    disk_ufs_create `expr 5 \* 512`m
    # rest of disk - either use growfs on prior or add partitions if needed
    #disk_ufs_create ...
}
strategy_add $PHASE_PARTITION_LWW allwinner_partition_image

allwinner_check_uboot ( ) {
    uboot_port_test ${SUNXI_UBOOT} ${SUNXI_UBOOT_BIN}
}
strategy_add $PHASE_CHECK allwinner_check_uboot

strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build \
	     UBLDR_LOADADDR=${UBLDR_LOADADDR}
strategy_add $PHASE_BOOT_INSTALL freebsd_ubldr_copy_ubldr .

#  use either as-is or workaround dts file
opi_use_dts="workaround"
if [ x"$opi_use_dts" = xworkaround ] ; then
    opi_dts_file_base=opipc+-workaround
    opi_dts_dir=${BOARDDIR}
else
    opi_dts_file_base=sun8i-h3-orangepi-pc-plus
    opi_dts_dir=/usr/src/sys/gnu/dts/arm
fi
#  use base and dir to get full dts path
opi_dts_full_path=${opi_dts_dir}/${opi_dts_file_base}.dts

make_workaround_fdt ( ) {
    mkdir -p ${WORKDIR}/opipc+
    # note: the echo expands the directory variables
    cmd=`echo MACHINE=arm /usr/src/sys/tools/fdt/make_dtb.sh \
    	      ${FREEBSD_SRC}/sys ${opi_dts_full_path} \
	      ${WORKDIR}/opipc+`
    echo === Running: $cmd ===
    sh -c "$cmd"
    if [ $? != 0 ] ; then
	echo make_workaround_fdt: command failed
	echo "  " $cmd
	exit 1
    fi
}

copy_workaround_fdt ( ) {
    destdir=$1
    if [ x = "x$destdir" ] ; then
	echo make_workaround_fdt: needs a destination directory argument
	exit 1
    else
	if [ "x$destdir" = xboot ] ; then
	    destdir=${BOARD_BOOT_MOUNTPOINT}  # not set at define time
	elif [ "x$destdir" = xbsd ] ; then
	    destdir=${BOARD_FREEBSD_MOUNTPOINT}/boot/dtb
	fi
	if [ ! -d $destdir ] ; then
	    echo make_workaround_fdt: $destdir is not a directory
	    exit 1
	fi
    fi
    echo === Copy dtb file to ${destdir}/sun8i-h3-orangepi-pc-plus.dtb ===
    cp ${WORKDIR}/opipc+/${opi_dts_file_base}.dtb \
       ${destdir}/sun8i-h3-orangepi-pc-plus.dtb
}

#strategy_add $PHASE_BOOT_INSTALL freebsd_install_fdt \
#	     ../gnu/dts/arm/sun8i-h3-orangepi-pc-plus.dts \
#	     ${BOARD_BOOT_MOUNTPOINT}/sun8i-h3-orangepi-pc-plus.dtb
#strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_install_fdt \
#	     ../gnu/dts/arm/sun8i-h3-orangepi-pc-plus.dts \
#	     ${BOARD_FREEBSD_MOUNTPOINT}/boot/dtb/orangepi-pc-plus.dtb

#  compiles dts twice but no big deal
strategy_add $PHASE_BOOT_INSTALL make_workaround_fdt
strategy_add $PHASE_BOOT_INSTALL copy_workaround_fdt boot
strategy_add $PHASE_FREEBSD_BOARD_INSTALL copy_workaround_fdt bsd

make_boot_install_boot_scr_file ( ) {
    echo "echo \"Loading U-boot loader: ubldr.bin\"" \
	 > ${BOARD_BOOT_MOUNTPOINT}/boot.cmd
#  not sure if we need to pre-load the dtb file
#    echo "" \
#	 >> ${BOARD_BOOT_MOUNTPOINT}/boot.cmd
    echo "load \${devtype} \${devnum}:${distro_bootpart}"\
	 "${UBLDR_LOADADDR}" ubldr.bin \
	 >> ${BOARD_BOOT_MOUNTPOINT}/boot.cmd
    echo "go ${UBLDR_LOADADDR}" \
	 >> ${BOARD_BOOT_MOUNTPOINT}/boot.cmd
    mkimage -A arm -T script -C none -n "Boot Commands" \
	    -d ${BOARD_BOOT_MOUNTPOINT}/boot.cmd \
	    ${BOARD_BOOT_MOUNTPOINT}/boot.scr
}
strategy_add $PHASE_FREEBSD_BOARD_INSTALL make_boot_install_boot_scr_file

# BeagleBone puts the kernel on the FreeBSD UFS partition.
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
# overlay/etc/fstab mounts the FAT partition at /boot/msdos
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir -p boot/msdos
# ubldr help and config files go on the UFS partition (after boot dir exists)
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_ubldr_copy boot
