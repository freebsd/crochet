#
# CONFIGURATION
#
# This fragment of shell script will be
# read into beaglebsd.sh when it runs.

# Uncomment to populate /usr/src
# Make sure you have at least a 2GB card
# (4GB recommended).
#
#INSTALL_USR_SRC=yes

# Uncomment to initialize /usr/ports
#
#INSTALL_USR_PORTS=yes

# Uncomment to avoid installworld (speeds up image-building
# when you're testing boot and kernel initialization issues)
#
# NO_WORLD=yes

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
#SD_SIZE=$((1950 * MB)) # for 2 Gigabyte card
#SD_SIZE=$((3900 * MB)) # for 4 Gigabyte card
#SD_SIZE=$((7900 * MB)) # for 8 Gigabyte card
#SD_SIZE=$((15900 * MB)) # for 16 Gigabyte card
#SD_SIZE=$((31900 * MB)) # for 32 Gigabyte card

#
# TOPDIR is the directory containing this script.
# As long as TOPDIR is on a disk with at least
# 5G or so of free space, you can probably
# use the settings below unchanged.
#

# The script assumes you're running a pretty recent
# copy of FreeBSD-CURRENT and have FreeBSD-CURRENT
# source code available in /usr/src.

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
