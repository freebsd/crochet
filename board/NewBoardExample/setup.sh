# NewBoardExample provides a detailed outline explaining how to define
# a new board.  This should help people add new board definitions to
# Crochet.

# Of course, it's probably easiest to start from a working
# definition.  Here are a few good ones to look at.  The
# biggest difference is how the boot bits are structured:
#   VersatilePB - Two images: one for booting kernel, other for World
#   BeagleBone - Single image with separate boot partition
#   GenericI386 - Single partition with boot bits integrated

# Comments below explain a lot of the theory and probably
# will make more sense after you skim one or more of the
# the real configurations above.

# When the configuration file invokes "board_setup Board", Crochet
# looks for an runs board/Board/setup.sh.  The setup.sh file is the
# only requirement for a board definition.  But many boards require
# additional files (e.g., etc/fstab, boot blobs, etc).  Those files
# can be stored in board/Board or subdirectories thereof and
# referenced via the ${BOARDDIR} variable.

# All of the helper files in lib (e.g., lib/disk.sh, lib/freebsd.sh)
# are already loaded when the board setup is run.  Those define lots
# of useful helper functions designed specifically to make board
# definitions simpler.

# There are a bunch of standard shell variables.  These three
# should be defined by any board definition:
KERNCONF=XXX
TARGET_ARCH=YYY
IMAGE_SIZE=$((1000 * 1000 * 1000))
# Right now, the kernel config must be part of the FreeBSD source
# tree.  (I would like to support out-of-tree configurations but
# haven't worked out the necessary build magic to make that possible.)

# If you require additional sources, define variables for them
# so users can override if they have them somewhere else.
# For example, a lot of boards use a special version of U-Boot:
#NEWBOARD_UBOOT_SRC=${TOPDIR}/u-boot-xxx

# The general structure is to register operations with strategy_add
# that will be run in different phases.
#
# Once all the configuration is complete, everything is run in order
# by phase.  See lib/base.sh for more details about how you can
# use "priority" to further tune the final ordering.

# A number of useful shell variables are defined for you:
#
# FREEBSD_SRC - Full path to FreeBSD source tree.  Defaults to /usr/src
#    but users may override if they have separate checkouts.
#    You should generally not override it here.
#
# WORKDIR - The full path of the work directory for temporary and built files.
#
# BOARDDIR - the full path of this directory.  Many boards have additional
#    files in subdirectories that can be referenced using ${BOARDDIR}/<subdir>
#
# BOARD_BOOT_MOUNTPOINT - between PHASE_BOOT_START and PHASE_BOOT_END,
#    this contains the full path where the boot partition is mounted.
#    The path name is based on the value of
#    BOARD_BOOT_MOUNTPOINT_PREFIX, which can be cusomized.
#
# BOARD_FREEBSD_MOUNTPOINT - between PHASE_FREEBSD_START and
#    PHASE_FREEBSD_END, this contains the mount point of the current
#    freebsd partition.  The mount point path is based on the value of
#    BOARD_FREEBSD_MOUNTPOINT_PREFIX, which can be customized.
#
# BOARD_CURRENT_MOUNTPOINT - between PHASE_BOOT_START and
#    PHASE_BOOT_END, PHASE_FREEBSD_START and PHASE_FREEBSD_END, and
#    during PHASE_CUSTOMIZE_PARTITION, this contains the mount point
#    of the current partition.

########################################################################
#
# CHECK PHASE:  This is used to test that necessary bits are
# available.  If you need python, gmake, cmake, or need to
# have certain third-party sources, check for those and tell
# the user how to get them if they're missing.

# For example, here's how to register the standard
# freebsd_current_test helper that checks that /usr/src exists and
# looks vaguely like a FreeBSD source checkout.  (This is actually
# already registered by Crochet for you but it doesn't hurt to run it
# again.)
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
# might find the FreeBSD xdev cross-compiler useful.
# This tests that it's available and prompts the user
# to install it if not:
#
# strategy_add $PHASE_CHECK freebsd_xdev_test

# Note: As a rule, Crochet never changes anything on the host system.
# This is why freebsd_xdev_test prompts the user to install the xdev
# tools rather than doing it for them.  Likewise, Crochet never
# downloads anything automatically.  Users might have locally tweaked
# and customized sources that they want to use instead.

########################################################################
#
# BUILD PHASE.
#
# There are actually several build phases.  The one you will probably
# use is PHASE_BUILD_OTHER.  At this point, FreeBSD world and kernel
# have already been built.
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
# TODO: ubldr is entirely generic except for the load address;
# converting it to a PIC binary would allow us to use a single binary
# on many platforms.

########################################################################
#
# PARTITIONING the IMAGE
#
# The PHASE_PARTITION_LWW is a little bit magic: Most phases simply
# run everything that's registered.  There are a very few "Last Write
# Wins" phases that only run the last item registered.  Partitioning
# is one such.  Since there can only be one item registered, you
# probably want to define a function.
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
# More complex partitioning may require you to muck with gpart, fdisk,
# or other tools directly.  You might even need to override
# PHASE_IMAGE_LWW to change how the image file itself is built.  If
# you have ideas for generalizing the tools in lib/disk.sh, please let
# me know.

########################################################################
#
# Mount Phase
#
# Like partitioning, mounting is also LWW.  The only partition that's
# generally mandatory is a UFS partition mounted at ${BOARD_FREEBSD_MOUNTPOINT},
# which you will have if you create at least one UFS partition.  (In fact,
# if that's all you need, you may not need to do anything here, since the
# default mount handler does that much by itself.)
#
# If your board needs a separate boot partition, create a FAT partition
# it will be mounted at ${BOARD_BOOT_MOUNTPOINT}.
#
# The default is equivalent to:
#
# myboard_mount_partitions ( ) {
#  board_mount_all
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
# this phase.  Useful bits here:

# If you built ubldr:
#
# strategy_add $PHASE_BOOT_INSTALL freebsd_ubldr_copy_ubldr ${BOARD_BOOT_MOUNTPOINT}

# Copy an FDT file.  The file is read from the FreeBSD source tree by
# default.  If the suffixes don't match, this function will
# automatically invoke the DTC compiler as necessary:
#
# strategy_add $PHASE_BOOT_INSTALL freebsd_install_fdt newboard.dts ${BOARD_BOOT_MOUNTPOINT}/newboard.dtb

# Examples that just copy one or more files; note we can use '.' here
# because PHASE_BOOT_INSTALL sets cwd appropriately:
#
# strategy_add $PHASE_BOOT_INSTALL cp ${BOARDDIR}/bootfiles/boot.bin .
# strategy_add $PHASE_BOOT_INSTALL cp ${BOARDDIR}/bootfiles/* .

########################################################################
#
# Populate FreeBSD partition
#
# The core system runs installworld/distribute/etc for you, so you can
# assume there's a basic FreeBSD installation at this point.  (If you
# really must, you can override PHASE_FREEBSD_INSTALLWORLD_LWW, but
# I've never needed to.  I've always been able to do what I wanted by
# either adding stuff to FREEBSD_EXTRA_xxx variables or by registering
# something at BOARD_INSTALL that modifies the installed world.)
#
# All of the PHASE_FREEBSD_XXX phases run with cwd set to
# BOARD_FREEBSD_MOUNTPOINT.  There are several such phases; look at
# lib/base.sh for details.  Most board-specific installation should
# occur in PHASE_FREEBSD_BOARD_INSTALL.
#

# Unlike installworld, installkernel is not done by default because
# some boards need this on the boot partition and some on the freebsd
# partition.  A helper makes this easy:
#
# strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .

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
#   ${BOARDDIR}/overlay/etc/fstab
#   ${BOARDDIR}/overlay/etc/rc.conf

########################################################################
#
# Other Phases
#
# The descriptions above only describe the most commonly-used phases.
# Read lib/base.sh to see the full list of supported phases and
# descriptions for most of them.
#
# It's relatively easy to add more phases if we need to.  However,
# remember that there are other ways to tweak ordering:
#
# * Items with the same phase and priority are run in the order
#   they were registered.  Within a single board definition file,
#   it usually suffices to just register things in the order you
#   want them run.
#
# * Priority can be used to manually force ordering.  This is
#   most helpful with options that may appear in different orders
#   in a config file.
#

########################################################################
#
# Board-specific Options
#
# Options can appear in an "option" directory under a board.
# Such options are run with BOARDDIR and OPTIONDIR both defined.
# For example, the RaspberryPi definition provides options to
# build and install the VideoCore kernel module and libraries.
#
# See ${TOPDIR}/option/Example/setup.sh for more information
# about options.
