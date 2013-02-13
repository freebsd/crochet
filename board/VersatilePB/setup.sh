FREEBSD_SRC=/usr/src
KERNCONF=VERSATILEPB
IMG=${WORKDIR}/FreeBSD-${KERNCONF}.img
FLASH=${WORKDIR}/FreeBSD-${KERNCONF}.flash
FREEBSD_INSTALLKERNEL_BOARD_ARGS=KERNEL_EXTRA_INSTALL=kernel.bin

board_construct_boot_partition ( ) {
    # dummy partition.
    disk_fat_create 8m
    # build kernel flush image
    #  following code is stolen from gonzo, thanks.
    rm -f $FLASH
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

    dd of=$FLASH bs=1M count=4 if=/dev/zero
    dd of=$FLASH bs=1 conv=notrunc if=${WORKDIR}/first_commands
    dd of=$FLASH bs=64k oseek=15 conv=notrunc if=${WORKDIR}/boot/kernel/kernel.bin
}

board_show_message ( ) {
    echo "DONE."
    echo "Completed disk image is in: ${IMG}"
    echo "And kernel image is in: ${FLASH}"
    echo
    echo "Try to run:"
    echo "qemu-system-arm -M versatilepb -m 128M -kernel ${FLASH} -cpu arm1176 -hda ${IMG}"
    echo
}
