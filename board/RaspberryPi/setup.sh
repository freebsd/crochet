KERNCONF=RPI-B
RPI_UBOOT_SRC=${TOPDIR}/u-boot-rpi
RPI_GPU_MEM=32

# You can use the most up-to-date boot files from the RaspberryPi project:
#RPI_FIRMWARE_SRC=${TOPDIR}/rpi-firmware

# Or save yourself a 400MB+ download and just use the files checked
# into this project:
RPI_FIRMWARE_SRC=${BOARDDIR}

. ${BOARDDIR}/mkimage.sh


strategy_add $PHASE_CHECK freebsd_current_test
strategy_add $PHASE_CHECK freebsd_dtc_test

raspberry_pi_check_uboot ( ) {
    uboot_test \
	RPI_UBOOT_SRC \
	"$RPI_UBOOT_SRC/board/raspberrypi/rpi_b/Makefile" \
	"git clone git://github.com/gonzoua/u-boot-pi.git ${RPI_UBOOT_SRC}"
}
strategy_add $PHASE_CHECK raspberry_pi_check_uboot

raspberry_pi_check_bootcode ( ) {
    if [ ! -f "${RPI_FIRMWARE_SRC}/boot/bootcode.bin" ]; then
	echo "Need Rasberry Pi closed-source boot files."
	echo "Use the following command to fetch them:"
	echo
	echo " $ git clone git://github.com/raspberrypi/firmware ${RPI_FIRMWARE_SRC}"
	echo
	echo "Run this script again after you have the files."
	exit 1
    fi
}
strategy_add $PHASE_CHECK raspberry_pi_check_bootcode

# Build U-Boot
strategy_add $PHASE_BUILD_OTHER uboot_patch ${RPI_UBOOT_SRC} ${BOARDDIR}/files/uboot_*.patch
strategy_add $PHASE_BUILD_OTHER uboot_configure ${RPI_UBOOT_SRC} rpi_b_config
strategy_add $PHASE_BUILD_OTHER uboot_build ${RPI_UBOOT_SRC}

# Build ubldr.
strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build UBLDR_LOADADDR=0x2000000

raspberry_pi_partition_image ( ) {
    disk_partition_mbr
    # Raspberry Pi boot loaders require FAT16, so this must be at least 17m
    disk_fat_create 17m 16
    disk_ufs_create
}

strategy_add $PHASE_PARTITION_LWW raspberry_pi_partition_image

raspberry_pi_mount_partitions ( ) {
    disk_fat_mount ${BOARD_BOOT_MOUNTPOINT}
    disk_ufs_mount ${BOARD_FREEBSD_MOUNTPOINT}
}

strategy_add $PHASE_MOUNT_LWW raspberry_pi_mount_partitions

raspberry_pi_populate_boot_partition ( ) {
    # Copy RaspberryPi boot files to FAT partition
    cp ${RPI_FIRMWARE_SRC}/boot/bootcode.bin .
    cp ${RPI_FIRMWARE_SRC}/boot/fixup.dat .
    cp ${RPI_FIRMWARE_SRC}/boot/fixup_cd.dat .
    cp ${RPI_FIRMWARE_SRC}/boot/start.elf .
    cp ${RPI_FIRMWARE_SRC}/boot/start_cd.elf .

    # Configure Raspberry Pi boot files
    cp ${RPI_FIRMWARE_SRC}/boot/config.txt .
    echo "gpu_mem=${RPI_GPU_MEM}" >> config.txt

    # RPi boot loader loads initial device tree file
    # Ubldr customizes this and passes it to the kernel.
    # (See overlay/boot/loader.rc)
    freebsd_install_fdt bcm2835-rpi-b.dts rpi-b.dtb
    echo "device_tree=rpi-b.dtb" >> config.txt
    echo "device_tree_address=0x100" >> config.txt

    # Copy U-Boot to FAT partition, configure to chain-boot ubldr
    mkimage ${RPI_UBOOT_SRC}/u-boot.bin uboot.img
    echo "kernel=uboot.img" >> config.txt
    cp ${RPI_FIRMWARE_SRC}/boot/uEnv.txt .

    # Install ubldr to FAT partition
    freebsd_ubldr_copy .

    # XXX For production use, we could boot faster by
    # bypassing u-boot and ubldr.  That requires the kernel
    # to accept the FDT directly from the RPi boot loader
    # using Linux kernel conventions.

    # Experimental.
    # Copy kernel.bin to FAT partition
    #FREEBSD_INSTALLKERNEL_BOARD_ARGS='KERNEL_KO=kernel.bin -DWITHOUT_KERNEL_SYMBOLS'
    #mkdir ${WORKDIR}/boot
    #freebsd_installkernel ${WORKDIR}
    #cp ${WORKDIR}/boot/kernel/kernel.bin > freebsd.bin
    #echo "kernel=freebsd.bin" >> config.txt
}

strategy_add $PHASE_BOOT_INSTALL raspberry_pi_populate_boot_partition

strategy_add $PHASE_FREEBSD_BASE_INSTALL freebsd_installkernel .
strategy_add $PHASE_FREEBSD_BASE_INSTALL mkdir boot/msdos
strategy_add $PHASE_FREEBSD_BASE_INSTALL freebsd_ubldr_copy_ubldr_help boot
