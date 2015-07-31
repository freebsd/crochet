KERNCONF=RPI-B
RPI_UBOOT_PORT="u-boot-rpi"
RPI_UBOOT_BIN="u-boot.img"
RPI_FIRMWARE_SRC=/usr/local/share/u-boot/${RPI_UBOOT_PORT}
RPI_GPU_MEM=32
IMAGE_SIZE=$((1000 * 1000 * 1000)) # 1 GB default
TARGET_ARCH=armv6

#
# Because of the complexity of the Raspberry Pi boot
# chain, this is one of the more complex board definitions.
#

. ${BOARDDIR}/mkimage.sh

raspberry_pi_check_uboot ( ) {
    uboot_port_test ${RPI_UBOOT_PORT} ${RPI_UBOOT_BIN}

    # Suggest the user clean old u-boot checkouts
    if [ -n ${TOPDIR} -a -d ${TOPDIR}/u-boot-rpi ]; then
        echo "Old u-boot git checkout found in: ${TOPDIR}/u-boot-rpi"
        echo -n 'Would you like it removed? [y/N] '
	read UBOOT
        case ${UBOOT} in
            y|Y)
                rm -fr ${TOPDIR}/u-boot-rpi
                ;;
            *)
                echo 'Not removing old u-boot git checkout'
                ;;
        esac
    fi
}
strategy_add $PHASE_CHECK raspberry_pi_check_uboot

# Build ubldr.
strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build UBLDR_LOADADDR=0x2000000

raspberry_pi_partition_image ( ) {
    disk_partition_mbr
    # Raspberry Pi boot loaders require FAT16, so this must be at least 17m
    disk_fat_create 17m 16
    disk_ufs_create
}

strategy_add $PHASE_PARTITION_LWW raspberry_pi_partition_image

raspberry_pi_populate_boot_partition ( ) {
    # Copy RaspberryPi boot files to FAT partition
    cp ${RPI_FIRMWARE_SRC}/* .
    touch uEnv.txt

    # Configure Raspberry Pi boot files
    echo "gpu_mem=${RPI_GPU_MEM}" >> config.txt

    # RPi boot loader loads initial device tree file
    # Ubldr customizes this and passes it to the kernel.
    # (See overlay/boot/loader.rc)
    freebsd_install_fdt rpi.dts rpi.dtb
    freebsd_install_fdt rpi.dts rpi.dts
    echo "device_tree=rpi.dtb" >> config.txt
    echo "device_tree_address=0x100" >> config.txt

    # Copy U-Boot to FAT partition, configure to chain-boot ubldr
    echo "kernel=u-boot.img" >> config.txt

    # Install ubldr to FAT partition
    freebsd_ubldr_copy_ubldr .
}

strategy_add $PHASE_BOOT_INSTALL raspberry_pi_populate_boot_partition

strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir boot/msdos
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_ubldr_copy_ubldr boot
