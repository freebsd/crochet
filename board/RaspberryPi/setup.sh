KERNCONF=RPI-B
RPI_UBOOT_SRC=${TOPDIR}/u-boot-rpi
RPI_GPU_MEM=32

# You can use the most up-to-date boot files from the RaspberryPi project:
#RPI_FIRMWARE_SRC=${TOPDIR}/rpi-firmware

# Or save yourself a 400MB+ download and just use the files checked
# into this project:
RPI_FIRMWARE_SRC=${BOARDDIR}

. ${BOARDDIR}/mkimage.sh
. ${BOARDDIR}/videocore.sh

# Note: A lot of the work here is done in "raspberry_pi_" functions.
# The standard "board_" functions just delegate to the "raspberry_pi_"
# versions.  This was done to simplify the (stil *very* experimental)
# BeagleBonePlusRaspberryPi board that tries to install everything
# for both boards onto a single image.

raspberry_pi_check_prerequisites ( ) {
    uboot_test \
	RPI_UBOOT_SRC \
	"$RPI_UBOOT_SRC/board/raspberrypi/rpi_b/Makefile" \
	"git clone git://github.com/gonzoua/u-boot-pi.git ${RPI_UBOOT_SRC}"

    if [ ! -f "${RPI_FIRMWARE_SRC}/boot/bootcode.bin" ]; then
	echo "Need Rasberry Pi closed-source boot files."
	echo "Use the following command to fetch them:"
	echo
	echo " $ git clone git://github.com/raspberrypi/firmware ${RPI_FIRMWARE_SRC}"
	echo
	echo "Run this script again after you have the files."
	exit 1
    fi
    mkimage_check
    videocore_src_check
    videocore_user_check
}

board_check_prerequisites ( ) {
    freebsd_current_test
    raspberry_pi_check_prerequisites
}

raspberry_pi_build_bootloader ( ) {
    # Closed-source firmware is already built.

    # Build U-Boot
    uboot_patch ${RPI_UBOOT_SRC} ${BOARDDIR}/files/uboot_*.patch
    uboot_configure ${RPI_UBOOT_SRC} rpi_b_config
    uboot_build ${RPI_UBOOT_SRC}

    # Build ubldr.
    freebsd_ubldr_build UBLDR_LOADADDR=0x2000000

    # Build videocore driver and userland
    videocore_build
    videocore_user_build
}

board_build_bootloader ( ) {
    raspberry_pi_build_bootloader
}

board_partition_image ( ) {
    disk_partition_mbr
    # Raspberry Pi boot loaders require FAT16, so this must be at least 17m
    disk_fat_create 17m 16
    disk_ufs_create
}

board_mount_partitions ( ) {
    disk_fat_mount ${BOARD_BOOT_MOUNTPOINT}
    disk_ufs_mount ${BOARD_FREEBSD_MOUNTPOINT}
}

raspberry_pi_populate_boot_partition ( ) {
    # Copy RaspberryPi boot files to FAT partition
    cp ${RPI_FIRMWARE_SRC}/boot/bootcode.bin ${BOARD_BOOT_MOUNTPOINT}
    cp ${RPI_FIRMWARE_SRC}/boot/fixup.dat ${BOARD_BOOT_MOUNTPOINT}
    cp ${RPI_FIRMWARE_SRC}/boot/fixup_cd.dat ${BOARD_BOOT_MOUNTPOINT}
    cp ${RPI_FIRMWARE_SRC}/boot/start.elf ${BOARD_BOOT_MOUNTPOINT}
    cp ${RPI_FIRMWARE_SRC}/boot/start_cd.elf ${BOARD_BOOT_MOUNTPOINT}

    # Configure Raspberry Pi boot files
    cp ${RPI_FIRMWARE_SRC}/boot/config.txt ${BOARD_BOOT_MOUNTPOINT}
    echo "gpu_mem=${RPI_GPU_MEM}" >> ${BOARD_BOOT_MOUNTPOINT}/config.txt

    # RPi boot loader loads initial device tree file
    # Ubldr customizes this and passes it to the kernel.
    # (See overlay/boot/loader.rc)
    freebsd_install_fdt bcm2835-rpi-b.dts ${BOARD_BOOT_MOUNTPOINT}/rpi-b.dtb
    echo "device_tree=rpi-b.dtb" >> ${BOARD_BOOT_MOUNTPOINT}/config.txt
    echo "device_tree_address=0x100" >> ${BOARD_BOOT_MOUNTPOINT}/config.txt

    # Use Oleksandr's uboot.img file.
    #cp ${RPI_FIRMWARE_SRC}/boot/uboot.img ${BOARD_BOOT_MOUNTPOINT}

    # Copy U-Boot to FAT partition, configure to chain-boot ubldr
    mkimage ${RPI_UBOOT_SRC}/u-boot.bin ${BOARD_BOOT_MOUNTPOINT}/uboot.img
    echo "kernel=uboot.img" >> ${BOARD_BOOT_MOUNTPOINT}/config.txt
    cp ${RPI_FIRMWARE_SRC}/boot/uEnv.txt ${BOARD_BOOT_MOUNTPOINT}

    # Install ubldr to FAT partition
    freebsd_ubldr_copy ${BOARD_BOOT_MOUNTPOINT}

    # XXX For production use, we could boot faster by
    # bypassing u-boot and ubldr.  That requires the kernel
    # to accept the FDT directly from the RPi boot loader
    # using Linux kernel conventions.

    # Experimental.
    # Copy kernel.bin to FAT partition
    #FREEBSD_INSTALLKERNEL_BOARD_ARGS='KERNEL_KO=kernel.bin -DWITHOUT_KERNEL_SYMBOLS'
    #mkdir ${WORKDIR}/boot
    #freebsd_installkernel ${WORKDIR}
    #cp ${WORKDIR}/boot/kernel/kernel.bin > ${BOARD_BOOT_MOUNTPOINT}/freebsd.bin
    #echo "kernel=freebsd.bin" >> ${BOARD_BOOT_MOUNTPOINT}/config.txt
}

board_populate_boot_partition ( ) {
    raspberry_pi_populate_boot_partition
}

board_populate_freebsd_partition ( ) {
    generic_board_populate_freebsd_partition
    mkdir ${BOARD_FREEBSD_MOUNTPOINT}/boot/msdos
    freebsd_ubldr_copy_ubldr_help ${BOARD_FREEBSD_MOUNTPOINT}/boot
}
