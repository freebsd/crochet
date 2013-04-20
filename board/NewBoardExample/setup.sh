# An example  outline explaining  what needs to  be in setup.sh  for a
# typical  new   board.   This  should  help  people   add  new  board
# definitions to Crochet.

# The kernel configuration, target architecture, and a default image
# size that should be used.  Right now, the kernel config must be part
# of the FreeBSD source tree.  (I would like to support out-of-tree
# configurations but haven't worked out the necessary build magic to
# make that possible.)
KERNCONF=XXX
TARGET_ARCH=YYY
IMAGE_SIZE=$((1000 * 1000 * 1000))

# If you require additional sources, define where you expect them.
# For example, a lot of boards use a special version of U-Boot:
#NEWBOARD_UBOOT_SRC=${TOPDIR}/u-boot-xxx

# The general structure is to register operations with strategy_add
# that will be run in different phases.
# There are also a number of 'options' that add their own operations.
#
# Once all the configuration is complete, everything is run in order
# by phase.  See lib/base.sh for more details about how you can
# use "priority" to further tune the final ordering.

# There are a number of shell variables you might find useful:
#
# WORKDIR - The full path of the work directory for temporary and built files.
# BOARDDIR - the full path of this directory.  Many boards have additional
#      files in subdirectories.
# BOARD_BOOT_MOUNTPOINT - full path where the boot partition is mounted
# BOARD_FREEBSD_MOUNTPOINT - full path of the freebsd partition

########################################################################
#
# CHECK PHASE:  This is used to test that necessary bits are
# available.  If you need python, gmake, cmake, or need to
# have certain third-party sources, check for those and tell
# the user how to get them if they're missing.

# Here's a helper that checks that /usr/src exists
# and looks vaguely like a FreeBSD source checkout.
# (This is actually run for you but it doesn't hurt to
# run it again.)
strategy_add $PHASE_CHECK freebsd_current_test

# If your board requires U-Boot, you may find uboot_test
# convenient.  Look at the BeagleBone or RaspberryPi board
# definitions for examples showing how to use this.
#
# myboard_check_uboot ( ) {
#     uboot_test <var name> <file to test> <command to fetch>
# }
# strategy_add $PHASE_CHECK myboard_check_uboot

# If you need to compile stuff for the target, you
# might find the FreeBSD xdev environment useful:
#
# strategy_add $PHASE_CHECK freebsd_xdev_test

########################################################################
#
# BUILD PHASE.
#
# There are actually several build phases.  The one you
# will probably use is PHASE_BUILD_OTHER.  At this point,
# FreeBSD world and kernel have already been built.
#

# As an example, if you need to build a custom bootloader,
# you might do it like this:
#
# myboard_build_bootloader ( ) {
#    cd ${FREEBSD_SRC}
#    buildenv=`make TARGET_ARCH=$TARGET_ARCH buildenvvars`
#
#    cd ${MYBOARD_BOOTLOADER_SRC}
#    eval $buildenv make <args>
# }
# strategy_add $PHASE_BUILD_OTHER myboard_build_bootloader

# There are helpers for U-Boot that you might find useful:
#
# strategy_add $PHASE_BUILD_OTHER uboot_patch ${NEWBOARD_UBOOT_SRC} ${BOARDDIR}/files/uboot_*.patch
# strategy_add $PHASE_BUILD_OTHER uboot_configure ${NEWBOARD_UBOOT_SRC} <config>
# strategy_add $PHASE_BUILD_OTHER uboot_build ${NEWBOARD_UBOOT_SRC}

# There's a helper to build FreeBSD's ubldr.  If you use U-Boot,
# you'll probably need this as well:
#
# strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build UBLDR_LOADADDR=0x2000000
#
# TODO: ubldr is entirely generic except for the load address; converting
# it to a PIC binary would remove this and allow us to use a single
# binary on many platforms.

########################################################################
#
# PARTITIONING the IMAGE
#
# The PHASE_PARTITION_LWW is a little bit magic:  Most phases
# simply run everything that's registered.  There are a very few
# "Last Write Wins" phases that only run the last item registered.
# Partitioning is one such.  Since there can only be one item registered,
# you probably want to define a function.
#
# The helpers in lib/disk.sh make this pretty trivial for most boards.
# For example, to use MBR partitioning with a 5 MB FAT partition
# and the rest UFS:
#
# myboard_partition_image ( ) {
#    disk_partition_mbr
#    disk_fat_create 5m
#    disk_ufs_create
# }
# strategy_add $PHASE_PARTITION_LWW myboard_partition_image
#
# More complex partitioning may require you to muck
# with gpart, fdisk, or other tools directly.
# If you have ideas for generalizing the tools in
# lib/disk.sh, please let me know.

########################################################################
#
# Mount Phase
#
# Like partitioning, mounting is also LWW.  The only partition that's
# generally mandatory is ${BOARD_FREEBSD_MOUNTPOINT}.
# If your board needs a separate boot partition, mount that
# at ${BOARD_BOOT_MOUNTPOINT}.
#
# myboard_mount_partitions ( ) {
#  disk_fat_mount ${BOARD_BOOT_MOUNTPOINT}
#  disk_ufs_mount ${BOARD_FREEBSD_MOUNTPOINT}
# }
# strategy_add $PHASE_MOUNT_LWW myboard_mount_partitions

########################################################################
#
# Populating BOOT partition
#
# PHASE_BOOT_INSTALL has some magic:  the cwd is set to
# BOARD_BOOT_MOUNTPOINT before these phases are invoked.
# This can sometimes simplify things a bit:
#
# If you don't need a separate boot partition, you can ignore
# this phase.
#
# If you built ubldr:
# strategy_add $PHASE_BOOT_INSTALL freebsd_ubldr_copy_ubldr ${BOARD_BOOT_MOUNTPOINT}/ubldr

# Copy an FDT file.  The file is read from the FreeBSD
# source tree by default.  If the suffixes don't match,
# this function will automatically invoke the DTC compiler
# as necessary:
# strategy_add $PHASE_BOOT_INSTALL freebsd_install_fdt newboard.dts ${BOARD_BOOT_MOUNTPOINT}/newboard.dtb

########################################################################
#
# Populate FreeBSD partition
#
# The core system runs installworld/distribute/etc for you,
# so you can assume there's a basic FreeBSD installation at
# this point.
#
# All of the PHASE_FREEBSD_XXX phases run with cwd set to
# BOARD_FREEBSD_MOUNTPOINT.  There are several such phases; look at
# lib/base.sh for details.  Most board-specific installation should
# occur in PHASE_FREEBSD_BOARD_INSTALL.
#

# installkernel is not registered for you because some boards need
# this on the boot partition and some on the freebsd partition.  The
# helper makes this easy:
#
# strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_installkernel .

########################################################################
#
# Overlay files:
#
# If you just need to override static files, put them in
# ${BOARDDIR}/overlay and they will be copied onto the FreeBSD
# partition for you.  (The overlay process is registered with an
# explicit priority to run very early in PHASE_FREEBSD_BOARD_INSTALL,
# so your own operations will follow it unless you also explicitly set
# a priority.  See lib/board.sh for details.)
#
# For example, most board definitions include the following:
#
#   overlay/etc/fstab
#   overlay/etc/rc.conf

########################################################################
#
# Other Phases
#
# The full process includes a number of phases not described
# above.  lib/base.sh includes a full list of phases and descriptions
# for most of them.
