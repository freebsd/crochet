#
# CONFIGURATION
#
# This fragment of shell script will be
# read into beaglebsd.sh when it runs.

#
# Size of the disk image that will be built.
# This is usually the same size as your card,
# but it can be smaller.
#
# MB and GB are predefined for convenience here
#
# The commented-out sizes are rounded down some to make
# sure they fit on a matching card.
#
SD_SIZE=$((350 * MB)) # Smallest size that works.
#SD_SIZE=$((1900 * GB)) # 2 Gigabyte image
#SD_SIZE=$((3900 * GB)) # 4 Gigabyte image
#SD_SIZE=$((7900 * GB)) # 8 Gigabyte image
#SD_SIZE=$((15900 * GB)) # 16 Gigabyte image
#SD_SIZE=$((31900 * GB)) # 32 Gigabyte image

#
# TOPDIR is the directory containing this script.
# As long as TOPDIR is on a disk with at least
# 5G or so of free space, you can probably
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
# in this directory, so you'll need about 150MB total space here.
#
# This directory doesn't need to exist yet.
# When you run the script, it will tell you how to get
# appropriate sources into this directory.
#
UBOOT_SRC=$TOPDIR/u-boot

# XXX Directory where build artifacts will go; this should be a
# directory with enough space for the final disk image.
#
# XXX The freebsd-armv6 build doesn't go here; it goes
# into /usr/obj/arm.arm instead.
#
BUILDOBJ=$TOPDIR/work

# Kernel configuration to use.
# The BEAGLEBONE configuration is in the armv6 sources.
# Otherwise, you might need to create the configuration file yourself.
#
KERNCONF=BEAGLEBONE

# The name of the final disk image.
# This file will be as large as SD_SIZE above, so make sure it's located
# somewhere with enough space.
IMG=${BUILDOBJ}/FreeBSD-${KERNCONF}.img
