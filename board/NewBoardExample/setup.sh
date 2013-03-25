# An example  outline explaining  what needs to  be in setup.sh  for a
# typical  new   board.   This  should  help  people   add  new  board
# definitions to Crochet.

# Note that all of the functions you override begin with a board_
# prefix.  If you find a need to override some other function, please
# let me know as I often rename and refactor other parts of Crochet.

# The kernel configuration that should be used.  Right now, this must
# be part of the FreeBSD source tree.  (I would like to support
# out-of-tree configurations but haven't worked out the necessary
# build magic to make that possible.)
KERNCONF=XXX

# If you use U-Boot, this is the directory the user will be
# told to checkout U-Boot to.
#NEWBOARD_UBOOT_SRC=${TOPDIR}/u-boot-xxx

board_check_prerequisites ( ) {
    # This function is called early to check that the necessary source
    # code and/or binary blobs are present.  The standard idiom here
    # is to exit if the code isn't present after prompting the user to
    # obtain the necessary code.

    # Here's a helper that checks that /usr/src exists
    # and looks vaguely like a FreeBSD source checkout.
    freebsd_current_test

    # If your board requires U-Boot, you may find uboot_test
    # convenient.  Look at the BeagleBone or RaspberryPi board
    # definitions for examples showing how to use this.
}

board_build_bootloader ( ) {
    # This function is probably misnamed.  It's really
    # a chance to build everything that isn't the FreeBSD
    # world and kernel.

    # You can use these helper functions to patch,
    # configure, and build U-Boot:
    # uboot_patch ${BOARDDIR}/files/uboot_*.patch
    # uboot_configure ${NEWBOARD_UBOOT_SRC} ubootconfig
    # uboot_build ${NEWBOARD_UBOOT_SRC}

    # Helper to build FreeBSD's ubldr.  If you use U-Boot,
    # you'll probably need this as well.
    # freebsd_ubldr_board UBLDR_LOADADDR=0x28000000
}

board_partition_image ( ) {
    # For most boards, the helpers in lib/disk.sh should
    # make this pretty routine.  For example, if your
    # board requires MBR partitioning with a 5 MB FAT
    # partition and the rest UFS, you can do that easily:

    #disk_partition_mbr
    #disk_fat_create 5m
    #disk_ufs_create

    # More complex partitioning may require you to muck
    # with gpart, fdisk, or other tools directly.
    # If you have ideas for generalizing the tools in
    # lib/disk.sh, please let me know.
}

board_mount_partitions ( ) {
    # Mount the partitions you created above so that the later stages
    # can copy files onto the partitions.  The only partition that's
    # generally mandatory is ${BOARD_FREEBSD_MOUNTPOINT}.
    # If your board needs a separate boot partition, mount that
    # at ${BOARD_BOOT_MOUNTPOINT}.

    # Again, there are utilities to simplify this for you:
    #disk_fat_mount ${BOARD_BOOT_MOUNTPOINT}
    #disk_ufs_mount ${BOARD_FREEBSD_MOUNTPOINT}
}

board_populate_boot_partition ( ) {
    # Copy stuff onto the Boot partition, if any.
    # If you don't need a separate boot partition, you
    # can just omit this entire function.

    # A few utilities that you might find useful:

    # Copy ubldr:
    # freebsd_ubldr_copy_ubldr ${BOARD_BOOT_MOUNTPOINT}/ubldr

    # Copy an FDT file.  The file is read from the FreeBSD
    # source tree by default.  If the suffixes don't match,
    # this function will automatically invoke the DTC compiler
    # as necessary:
    # freebsd_install_fdt newboard.dts ${BOARD_BOOT_MOUNTPOINT}/newboard.dtb

    # NOTE:  FreeBSD/ARM is moving towards a design where the
    # early boot stages (such as U-Boot) load the DTB file into
    # memory and it then gets passed automatically to later stages
    # and ultimately to the kernel.
}

board_populate_freebsd_partition ( ) {
    # Populate the FreeBSD partition.

    # The following helper function does almost everything you need.
    # It installs kernel, world, and obeys some user settings
    # to install source, ports, etc.  It finishes by copying
    # the board overlay and the work overlay directories:

    # generic_board_populate_freebsd_partition

    # A lot of standard customization of the FreeBSD partition
    # can be done by just putting the necessary files into
    # ${BOARDDIR}/overlay.  For example, most board definitions
    # include the following:
    #   overlay/etc/fstab
    #   overlay/etc/rc.conf

    # If you need to construct these files dynamically, please don't
    # create them in ${BOARDDIR}.  You can either create them directly
    # in the image at ${BOARD_FREEBSD_MOUNTPOINT} or create them in
    # ${WORKDIR}/overlay before calling
    # generic_board_populate_freebsd_partition.  The latter approach
    # is especially convenient if you want to create fstab on-the-fly
    # as part of your partition calculations.

    # Of course, you may need to do additional things in this
    # function.
}

# There are a few other customization hooks that may be
# needed in unusual circumstances.  Look carefully at the
# top-level crochet.sh for more information.