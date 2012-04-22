#
# CONFIGURATION
#

#
# Size of the disk image that will be built.
#
# MB and GB are predefined for convenience here
#
# This is usually the same size as your card,
# but it can be smaller.  Making it smaller will
# make things a little bit faster.
#
SD_SIZE=$((32 * MB)) # Smallest size that works.
#SD_SIZE=$((4 * GB)) # 4 Gigabyte card
#SD_SIZE=$((8 * GB)) # 8 Gigabyte card
#SD_SIZE=$((16 * GB)) # 16 Gigabyte card
#SD_SIZE=$((32 * GB)) # 32 Gigabyte card

#
# TOPDIR is the directory containing this script.
# As long as TOPDIR is on a disk with at least
# 10G or so of free space, you can probably
# use the settings below unchanged.
#

# The script assumes you're running a pretty recent
# copy of FreeBSD-CURRENT and have FreeBSD-CURRENT
# source code available.

# Directory that will hold FreeBSD source for the ARMv6 version of
# FreeBSD (about 1.5GB).  These sources are not yet merged into
# FreeBSD-CURRENT, so you cannot yet just set this to /usr/src.
#
# This directory doesn't need to exist yet.
# When you run the script, it will tell you how to get
# appropriate sources into this directory.
#
FREEBSD_SRC=$TOPDIR/src-armv6

# Directory to hold U-Boot source code.
# The U-Boot source is about 120MB. U-Boot will also be compiled
# in this directory, so you'll need about 200MB total space here.
#
# This directory doesn't need to exist yet.
# When you run the script, it will tell you how to get
# appropriate sources into this directory.
#
UBOOT_SRC=$TOPDIR/u-boot

# Directory where build artifacts will go; this should be a directory
# with at least 4G of free space, plus enough space for the final disk
# image.
#
BUILDOBJ=$TOPDIR/obj

# Kernel configuration to use.
# The BEAGLEBONE configuration is in the armv6 sources.
# Otherwise, you might need to create the configuration file yourself.
#
KERNCONF=BEAGLEBONE

# Where the disk image will be built.
# This file will be as large as SD_SIZE above, so make sure it's located
# somewhere with enough space.
IMG=${BUILDOBJ}/_.disk.full
