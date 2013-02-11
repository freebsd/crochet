FREEBSD_SRC=/usr/src
KERNCONF=VERSATILEPB
IMG=${WORKDIR}/FreeBSD-${KERNCONF}.img
FLASH=${WORKDIR}/FreeBSD-${KERNCONF}.flash

# TODO: The following is brittle and will break
# if anything changes in how the objdir is handled.
KERNELBIN=${WORKDIR}/obj/arm.armv6`realpath ${FREEBSD_SRC}`/sys/${KERNCONF}/kernel.bin

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

    dd of=$FLASH bs=1M count=4 if=/dev/zero
    dd of=$FLASH bs=1 conv=notrunc if=${WORKDIR}/first_commands

    # TODO: $KERNELBIN is a very brittle approach.
    # Better to use something like the following:

    # mkdir ${WORKDIR}/kernel
    # freebsd_kernel_install ${WORKDIR}/kernel
    # dd .... if=${WORKDIR}/kernel/...

    dd of=$FLASH bs=64k oseek=15 conv=notrunc if=$KERNELBIN
    
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
