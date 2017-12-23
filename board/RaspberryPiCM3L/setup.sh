KERNCONF=GENERIC
RPI3_UBOOT_PORT="u-boot-rpi3"
RPI3_UBOOT_BIN="u-boot.bin"
RPI3_UBOOT_PATH="/usr/local/share/u-boot/${RPI3_UBOOT_PORT}"
IMAGE_SIZE=$((2000 * 1000 * 1000))
TARGET_ARCH=aarch64
TARGET=aarch64
DTB_REPO="https://github.com/raspberrypi/firmware/blob/master/boot/"
RPICM3_FIRMWARE_PORT="rpi-firmware"
RPICM3_FIRMWARE_PATH="/usr/local/share/${RPICM3_FIRMWARE_PORT}"

# Not used - just in case someone wants to use a manual ubldr.  Obtained
# from 'printenv' in boot0: kernel_addr_r=0x42000000
#UBLDR_LOADADDR=0x42000000

rpi3_check_uboot ( ) {
    uboot_port_test ${RPI3_UBOOT_PORT} ${RPI3_UBOOT_BIN}
}
strategy_add $PHASE_CHECK rpi3_check_uboot

rpi_cm3_check_firmware ( ) {
    if [ ! -d ${RPICM3_FIRMWARE_PATH} ]; then
        echo "please install sysutils/${RPICM3_FIRMWARE_PORT} and re-run this script."
	echo "You can do this with:"
	echo "$ sudo pkg install sysutils/${RPICM3_FIRMWARE_PORT}"
	echo "or by building the port:"
	echo " $ cd /usr/ports/sysutils/${RPICM3_FIRMWARE_PORT}"
	echo " $ make install"
	exit 1
    fi
    echo "Found rpi-firmware port in:"
    echo "    ${RPICM3_FIRMWARE_PORT}"
}
strategy_add $PHASE_CHECK rpi_cm3_check_firmware

#
# RPi3 uses EFI, so the first partition will be a FAT partition.
#
rpi3_partition_image ( ) {
    disk_partition_mbr
    # Use FAT16.  The minimum space requirement for FAT32 is too big for this.
    disk_fat_create 50m 16
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW rpi3_partition_image

raspberry_pi_populate_boot_partition ( ) {
    echo bootaa64 > startup.nsh
    mkdir -p EFI/BOOT

    cp ${RPICM3_FIRMWARE_PATH}/LICENCE.broadcom .
    cp ${UBOOT_PATH}/README .
    cp ${RPICM3_FIRMWARE_PATH}/bootcode.bin .
    cp ${RPICM3_FIRMWARE_PATH}/fixup.dat .
    cp ${RPICM3_FIRMWARE_PATH}/fixup_cd.dat .
    cp ${RPICM3_FIRMWARE_PATH}/fixup_x.dat .
    cp ${RPICM3_FIRMWARE_PATH}/start.elf .
    cp ${RPICM3_FIRMWARE_PATH}/start_cd.elf .
    cp ${RPICM3_FIRMWARE_PATH}/start_x.elf .
    cp ${UBOOT_PATH}/u-boot.bin .
    cp ${UBOOT_PATH}/armstub8.bin .

    # Populate config.txt
    echo "arm_control=0x200" > config.txt
    echo "dtparam=audio=on,i2c_arm=on,spi=on" >> config.txt
    echo "dtoverlay=mmc" >> config.txt
    echo "dtoverlay=pi3-disable-bt" >> config.txt
    echo "device_tree_address=0x4000" >> config.txt
    echo "kernel=u-boot.bin" >> config.txt

    # Fetch the dtb
    dtb="bcm2710-rpi-cm3.dtb"
    fetch -o ${dtb} "${DTB_REPO}/${dtb}?raw=true"

    # Fetch all the overlays we need
    mkdir overlays
    overlays="mmc.dtbo pi3-disable-bt.dtbo"
    for i in ${overlays}; do
        fetch -o overlays/${i} "${DTB_REPO}/overlays/${i}?raw=true"
    done

}
strategy_add $PHASE_BOOT_INSTALL raspberry_pi_populate_boot_partition

# Build & install loader.efi.
strategy_add $PHASE_BUILD_OTHER freebsd_loader_efi_build
strategy_add $PHASE_BOOT_INSTALL freebsd_loader_efi_copy EFI/BOOT/bootaa64.efi

# RPi3 puts the kernel on the FreeBSD UFS partition.
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
# overlay/etc/fstab mounts the FAT partition at /boot/efi
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir -p boot/efi
