#!/bin/sh -e

# Directory containing this script.
TOPDIR=`cd \`dirname $0\`; pwd`
# Useful values
MB=$((1024 * 1024))
GB=$((1024 * $MB))

#
# Get the config values:
#
. $TOPDIR/beaglebsd-config.sh


mkdir -p ${BUILDOBJ}
# Why does this have no effect?
MAKEOBJDIRPREFIX=${BUILDOBJ}/_freebsd_build
# Clean out old log files before we start.
rm -f ${BUILDOBJ}/*.log

#
# Check various prerequisites
#

# We need TIs modified U-Boot sources
if [ ! -f "$UBOOT_SRC/board/ti/am335x/Makefile" ]; then
    # Use TIs U-Boot sources that know about am33x processors
    echo "Expected to see U-Boot sources in $UBOOT_SRC"
    echo "Use the following command to get the U-Boot sources"
    echo
    echo "git clone git://arago-project.org/git/projects/u-boot-am33x.git $UBOOT_SRC"
    echo
    echo "Edit \$UBOOT_SRC in beaglebsd-config.sh if you want the sources in a different directory."
    echo "Run this script again after you have the U-Boot sources installed."
    exit 1
fi
echo "Found U-Boot sources in $UBOOT_SRC"

# We need the cross-tools for arm, if they're not already built.
if [ -z `which arm-freebsd-cc` ]; then
    echo "Can't find FreeBSD xdev tools for ARM."
    echo "If you have FreeBSD-CURRENT sources in /usr/src, you can build these with the following command:"
    echo
    echo "cd /usr/src && sudo make xdev XDEV=arm XDEV_ARCH=arm"
    echo
    echo "Run this script again after you have the xdev tools installed."
    exit 1
fi
echo "Found FreeBSD xdev tools for ARM"

# We need Damjan Marion's FreeBSD-armv6 tree (we can tell it's the right
# one by the presence of the BEAGLEBONE configuration file).
# Someday, this will all be merged and we can just rely on FreeBSD-CURRENT.
if [ \! -f "$FREEBSD_SRC/sys/arm/conf/BEAGLEBONE" ]; then
    echo "Need FreeBSD-armv6 tree."
    echo "You can obtain this with the folowing command:"
    echo
    echo "mkdir -p $FREEBSD_SRC && svn co http://svn.freebsd.org/base/projects/armv6 $FREEBSD_SRC"
    echo
    echo "Edit \$FREEBSD_SRC in beaglebsd-config.sh if you want the sources in a different directory."
    echo "Run this script again after you have the sources installed."
    exit 1
fi
echo "Found FreeBSD-armv6 source tree in $FREEBSD_SRC"

#
# Build and configure U-Boot
#
if [ ! -f "$UBOOT_SRC/u-boot.img" ]; then
    cd "$UBOOT_SRC"
    echo "Patching U-Boot. (Logging to ${BUILDOBJ}/_.uboot.patch.log)"
    # Works around a FreeBSD bug (freestanding builds require libc).
    patch -p1 < ../files/uboot_patch1_add_libc_to_link_on_FreeBSD.patch > ${BUILDOBJ}/_.uboot.patch.log 2>&1
    # Turn on some additional U-Boot features not ordinarily present in TIs build.
    patch -p1 < ../files/uboot_patch2_add_options_to_am335x_config.patch >> ${BUILDOBJ}/_.uboot.patch.log 2>&1
    # Fix a U-Boot bug that has been fixed in the master sources but not yet in TIs sources.
    patch -p1 < ../files/uboot_patch3_fix_api_disk_enumeration.patch >> ${BUILDOBJ}/_.uboot.patch.log 2>&1

    echo "Configuring U-Boot. (Logging to ${BUILDOBJ}/_.uboot.configure.log)"
    gmake CROSS_COMPILE=arm-freebsd- am335x_evm_config > ${BUILDOBJ}/_.uboot.configure.log 2>&1
    echo "Building U-Boot. (Logging to ${BUILDOBJ}/_.uboot.build.log)"
    gmake CROSS_COMPILE=arm-freebsd- > ${BUILDOBJ}/_.uboot.build.log 2>&1
    cd $TOPDIR
fi

#
# Build FreeBSD for BeagleBone
#
if [ ! -f ${BUILDOBJ}/_.built-world ]; then
    echo "Building FreeBSD-armv6 world at "`date`" (Logging to ${BUILDOBJ}/_.buildworld.log)"
    cd $FREEBSD_SRC
    make TARGET_ARCH=arm TARGET_CPUTYPE=armv6 buildworld > ${BUILDOBJ}/_.buildworld.log 2>&1
    cd $TOPDIR
    touch ${BUILDOBJ}/_.built-world
fi

if [ ! -f ${BUILDOBJ}/_.built-kernel ]; then
    echo "Building FreeBSD-armv6 kernel at "`date`" (Logging to ${BUILDOBJ}/_.buildkernel.log)"
    cd $FREEBSD_SRC
    make TARGET_ARCH=arm KERNCONF=$KERNCONF buildkernel > ${BUILDOBJ}/_.buildkernel.log 2>&1
    cd $TOPDIR
    touch ${BUILDOBJ}/_.built-kernel
fi

# TODO: Build ubldr (see below)

#
# Create and partition the disk image
#
echo "Creating the raw disk image in ${IMG}"
[ -f ${IMG} ] && rm -f ${IMG}
dd if=/dev/zero of=${IMG} bs=1 seek=${SD_SIZE} count=0
MD=`mdconfig -a -t vnode -f ${IMG}`

echo "Partitioning the raw disk image at "`date`
# TI AM335x ROM code requires we use MBR partitioning.
gpart create -s MBR ${MD}
gpart add -b 63 -s10m -t '!12' ${MD}
gpart set -a active -i 1 ${MD}
gpart add -t freebsd ${MD}
echo gpart commit ${MD}
gpart commit ${MD}

echo "Formatting the FAT partition at "`date`
# Note: Select FAT12, FAT16, or FAT32 depending on the size of the partition.
newfs_msdos -L "boot" -F 12 ${MD}s1
[ -d ${BUILDOBJ}/_.mounted_fat ] && rmdir ${BUILDOBJ}/_.mounted_fat
mkdir ${BUILDOBJ}/_.mounted_fat
mount_msdosfs /dev/${MD}s1 ${BUILDOBJ}/_.mounted_fat

echo "Formatting the UFS partition at "`date`
bsdlabel -w ${MD}s2
newfs ${MD}s2a
[ -d ${BUILDOBJ}/_.mounted_ufs ] && rmdir ${BUILDOBJ}/_.mounted_ufs
mkdir ${BUILDOBJ}/_.mounted_ufs
mount /dev/${MD}s2a ${BUILDOBJ}/_.mounted_ufs

#
# Install U-Boot onto UFS partition.
#
echo "Installing U-Boot onto the FAT partition at "`date`
cp ${UBOOT_SRC}/MLO ${BUILDOBJ}/_.mounted_fat/
cp ${UBOOT_SRC}/u-boot.img ${BUILDOBJ}/_.mounted_fat/
cp ${TOPDIR}/files/uEnv.txt ${BUILDOBJ}/_.mounted_fat/

#
# TODO: Install FreeBSD's ubldr onto FAT partition.
# For this to work:
#   1) ubldr needs to be linked with a start address of 0x80200000 when built for BeagleBone
#   2) ubldr needs to understand MBR partitioning
#   3) ubldr needs to load the kernel from the first UFS slice even if that slice is not marked as the active partition
#   4) files/uEnv.txt needs to be tweaked to load ubldr instead of kernel.bin
#   5) files/uEnv.txt needs to use 'bootelf' to start the ELF ubldr image instead of 'go' to start the binary kernel image
#
# Advantages of having U-Boot load ubldr and having ubldr load the kernel:
#  1) We can use kernel modules.
#  2) We can use installkernel to put the kernel onto the UFS partition.
#  3) It's easier to be self-hosting.
#
#cp /usr/obj/arm.arm/${FREEBSD_SRC}/sys/boot/arm/uboot/ubldr ${BUILDOBJ}/_.mounted_fat/
#

# Install FreeBSD kernel.bin into the FAT partition
# TODO: Remove this once ubldr works.  ubldr can load
# the ELF kernel directly from UFS.
cp /usr/obj/arm.arm/${FREEBSD_SRC}/sys/${KERNCONF}/kernel.bin ${BUILDOBJ}/_.mounted_fat/

#
# Install FreeBSD kernel and world onto UFS partition.
#
echo "Installing FreeBSD onto the UFS partition at "`date`
cd $FREEBSD_SRC
make TARGET_ARCH=arm TARGET_CPUTYPE=armv6 DESTDIR=${BUILDOBJ}/_.mounted_ufs KERNCONF=${KERNCONF} installkernel > ${BUILDOBJ}/_.installkernel.log 2>&1
make TARGET_ARCH=arm TARGET_CPUTYPE=armv6 DESTDIR=${BUILDOBJ}/_.mounted_ufs installworld > ${BUILDOBJ}/_.installworld.log 2>&1
make TARGET_ARCH=arm TARGET_CPUTYPE=armv6 DESTDIR=${BUILDOBJ}/_.mounted_ufs distrib-dirs > ${BUILDOBJ}/_.distrib-dirs.log 2>&1
make TARGET_ARCH=arm TARGET_CPUTYPE=armv6 DESTDIR=${BUILDOBJ}/_.mounted_ufs distribution > ${BUILDOBJ}/_.distribution.log 2>&1

# Configure FreeBSD
# These could be generated dynamically if we needed.
echo "Configuring FreeBSD"
cp ${TOPDIR}/files/rc.conf ${BUILDOBJ}/_.mounted_ufs/etc/
cp ${TOPDIR}/files/fstab ${BUILDOBJ}/_.mounted_ufs/etc/

#
# Unmount and clean up.
#
echo "Unmounting the disk image"
cd $TOPDIR
umount ${BUILDOBJ}/_.mounted_fat
umount ${BUILDOBJ}/_.mounted_ufs
mdconfig -d -u ${MD}

#
# We have a finished image; explain what to do with it.
#
echo "DONE.  Completed disk image is in: ${IMG}"
echo
echo "Copy to a MicroSDHC card using a command such as:"
echo "dd if=${IMG} of=/dev/da0"
echo "(Replace /dev/da0 with the appropriate path for your SDHC card reader.)"
echo
