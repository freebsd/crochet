KERNCONF=RPI-B
RPI_UBOOT_SRC=${TOPDIR}/u-boot-rpi
VC_SRC=${TOPDIR}/vchiq-freebsd
VC_USER_SRC=${TOPDIR}/vcuserland
RPI_GPU_MEM=32

# You can use the most up-to-date boot files from the RaspberryPi project:
#RPI_FIRMWARE_SRC=${TOPDIR}/rpi-firmware

# Or save yourself a 400MB+ download and just use the files checked
# into this project:
RPI_FIRMWARE_SRC=${BOARDDIR}

. ${BOARDDIR}/mkimage.sh
. ${BOARDDIR}/videocore.sh

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

raspberry_pi_populate_boot_partition ( ) {

    # Copy RaspberryPi boot files to FAT partition
    cp ${RPI_FIRMWARE_SRC}/boot/bootcode.bin ${FAT_MOUNT}
    cp ${RPI_FIRMWARE_SRC}/boot/fixup.dat ${FAT_MOUNT}
    cp ${RPI_FIRMWARE_SRC}/boot/fixup_cd.dat ${FAT_MOUNT}
    cp ${RPI_FIRMWARE_SRC}/boot/start.elf ${FAT_MOUNT}
    cp ${RPI_FIRMWARE_SRC}/boot/start_cd.elf ${FAT_MOUNT}

    # Configure Raspberry Pi boot files
    cp ${RPI_FIRMWARE_SRC}/boot/config.txt ${FAT_MOUNT}
    echo "gpu_mem=${RPI_GPU_MEM}" >> ${FAT_MOUNT}/config.txt

    # RPi boot loader loads initial device tree file
    # Ubldr customizes this and passes it to the kernel.
    # (See overlay/boot/loader.rc)
    freebsd_install_fdt bcm2835-rpi-b.dts ${FAT_MOUNT}/rpi-b.dtb
    echo "device_tree=rpi-b.dtb" >> ${FAT_MOUNT}/config.txt
    echo "device_tree_address=0x100" >> ${FAT_MOUNT}/config.txt

    # Use Oleksandr's uboot.img file.
    #cp ${RPI_FIRMWARE_SRC}/boot/uboot.img ${FAT_MOUNT}

    # Copy U-Boot to FAT partition, configure to chain-boot ubldr
    mkimage ${RPI_UBOOT_SRC}/u-boot.bin ${FAT_MOUNT}/uboot.img
    echo "kernel=uboot.img" >> ${FAT_MOUNT}/config.txt
    cp ${RPI_FIRMWARE_SRC}/boot/uEnv.txt ${FAT_MOUNT}

    # Install ubldr to FAT partition
    freebsd_ubldr_copy ${FAT_MOUNT}

    # Experimental.
    # Copy kernel.bin to FAT partition
    #FREEBSD_INSTALLKERNEL_BOARD_ARGS='KERNEL_KO=kernel.bin -DWITHOUT_KERNEL_SYMBOLS'
    #mkdir ${WORKDIR}/boot
    #freebsd_installkernel ${WORKDIR}
    #cp ${WORKDIR}/boot/kernel/kernel.bin > ${FAT_MOUNT}/freebsd.bin
    #echo "kernel=freebsd.bin" >> ${FAT_MOUNT}/config.txt
}

board_construct_boot_partition ( ) {
    echo "Setting up boot partition"
    FAT_MOUNT=${WORKDIR}/_.mounted_fat
    # Raspberry Pi boot loaders require FAT16, so this must be at least 17m
    disk_fat_create 17m 16
    disk_fat_mount ${FAT_MOUNT}

    raspberry_pi_populate_boot_partition ${FAT_MOUNT}

    cd ${FAT_MOUNT}
    customize_boot_partition ${FAT_MOUNT}
    disk_fat_unmount ${FAT_MOUNT}
    unset FAT_MOUNT
}

board_customize_freebsd_partition ( ) {
    mkdir $1/boot/msdos
    freebsd_ubldr_copy_ubldr_help $1/boot
}
