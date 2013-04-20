KERNCONF=VERSATILEPB
TARGET_ARCH=armv6
IMAGE_SIZE=$((1000 * 1000 * 1000))
VERSATILEPB_FLASH=${WORKDIR}/FreeBSD-${KERNCONF}.flash
FREEBSD_INSTALLKERNEL_BOARD_ARGS="KERNEL_EXTRA_INSTALL=kernel.bin"

#
# Support for building an image suitable for booting on qemu.
#
# Note that the default image generation, partitioning,
# and installworld works fine here so we only have to
# define how to build the flash image.
#

versatilepb_build_flash_image ( ) {
    #  following code is stolen from gonzo, thanks.
    rm -f $VERSATILEPB_FLASH
    # set r0..r3 to zero
    /usr/bin/printf "\0\0\240\343" > ${WORKDIR}/first_commands
    /usr/bin/printf "\0\020\240\343" >> ${WORKDIR}/first_commands
    /usr/bin/printf "\0\040\240\343" >> ${WORKDIR}/first_commands
    /usr/bin/printf "\0\060\240\343" >> ${WORKDIR}/first_commands
    # jump to kernel entry point
    /usr/bin/printf "\001\366\240\343" >> ${WORKDIR}/first_commands
    # install kernel
    [ ! -d ${WORKDIR}/_.kernel.bin ] && mkdir ${WORKDIR}/_.kernel.bin
    freebsd_installkernel ${WORKDIR}/_.kernel.bin

    dd of=$VERSATILEPB_FLASH bs=1M count=4 if=/dev/zero
    dd of=$VERSATILEPB_FLASH bs=1 conv=notrunc if=${WORKDIR}/first_commands
    dd of=$VERSATILEPB_FLASH bs=64k oseek=15 conv=notrunc if=${WORKDIR}/boot/kernel/kernel.bin
}
strategy_add $PHASE_BUILD_OTHER versatilepb_build_flash_image

versatilepb_instructions ( ) {
    echo "DONE."
    echo "Completed disk image is in: ${IMG}"
    echo "And kernel image is in: ${VERSATILEPB_FLASH}"
    echo
    echo "Use with qemu:"
    echo
    echo " $ qemu-system-arm -M versatilepb -m 128M -kernel ${VERSATILEPB_FLASH} -cpu arm1176 -hda ${IMG}"
    echo
}
strategy_add $PHASE_GOODBYE_LWW versatilepb_instructions
