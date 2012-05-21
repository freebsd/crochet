#!/bin/sh -e

# Directory containing this script.
TOPDIR=`cd \`dirname $0\`; pwd`
# Useful values
MB=$((1000 * 1000))
GB=$((1000 * $MB))

#
# Get the config values:
#
echo "Loading configuration values"
. $TOPDIR/beaglebsd-config.sh

if [ -f $TOPDIR/beaglebsd-config-local.sh ]; then
    echo "Loading local configuration overrides"
    . $TOPDIR/beaglebsd-config-local.sh
fi

# Round down to sector multiple.
SD_SIZE=$(( (SD_SIZE / 512) * 512))

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

# We need the FreeBSD-armv6 tree (we can tell it's the right
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
else
    echo "Using U-Boot from previous build."
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
else
    echo "Using FreeBSD world from previous build"
fi

if [ ! -f ${BUILDOBJ}/_.built-kernel ]; then
    echo "Building FreeBSD-armv6 kernel at "`date`" (Logging to ${BUILDOBJ}/_.buildkernel.log)"
    cd $FREEBSD_SRC
    make TARGET_ARCH=arm KERNCONF=$KERNCONF buildkernel > ${BUILDOBJ}/_.buildkernel.log 2>&1
    cd $TOPDIR
    touch ${BUILDOBJ}/_.built-kernel
else
    echo "Using FreeBSD kernel from previous build"
fi

# TODO: Build ubldr (see below)

#
# Create and partition the disk image
#
echo "Creating the raw disk image in ${IMG}"
[ -f ${IMG} ] && rm -f ${IMG}
dd if=/dev/zero of=${IMG} bs=1 seek=${SD_SIZE} count=0 >/dev/null 2>&1
MD=`mdconfig -a -t vnode -f ${IMG}`

echo "Partitioning the raw disk image at "`date`
# TI AM335x ROM code requires we use MBR partitioning.
gpart create -s MBR -f x ${MD}
gpart add -b 63 -s3m -t '!12' -f x ${MD}
gpart set -a active -i 1 -f x ${MD}
gpart add -t freebsd -f x ${MD}
gpart commit ${MD}

echo "Formatting the FAT partition at "`date`
# Note: Select FAT12, FAT16, or FAT32 depending on the size of the partition.
newfs_msdos -L "boot" -F 12 ${MD}s1 >/dev/null
[ -d ${BUILDOBJ}/_.mounted_fat ] && rmdir ${BUILDOBJ}/_.mounted_fat
mkdir ${BUILDOBJ}/_.mounted_fat
mount_msdosfs /dev/${MD}s1 ${BUILDOBJ}/_.mounted_fat

echo "Formatting the UFS partition at "`date`
newfs ${MD}s2 >/dev/null
# Turn on Softupdates
tunefs -n enable /dev/${MD}s2
# Turn on SUJ
# This makes reboots tolerable if you just pull power on the BB
tunefs -j enable /dev/${MD}s2
# Turn on NFSv4 ACLs
tunefs -N enable /dev/${MD}s2
# SUJ journal to 4M (minimum size)
# A slow SDHC reads about 1MB/s, so the default 30M journal
# can introduce a 30s delay into the boot.
tunefs -S 4194304 /dev/${MD}s2
[ -d ${BUILDOBJ}/_.mounted_ufs ] && rmdir ${BUILDOBJ}/_.mounted_ufs
mkdir ${BUILDOBJ}/_.mounted_ufs
mount /dev/${MD}s2 ${BUILDOBJ}/_.mounted_ufs

#
# Install U-Boot onto FAT partition.
#
echo "Installing U-Boot onto the FAT partition at "`date`
cp ${UBOOT_SRC}/MLO ${BUILDOBJ}/_.mounted_fat/
cp ${UBOOT_SRC}/u-boot.img ${BUILDOBJ}/_.mounted_fat/
cp ${TOPDIR}/files/uEnv.txt ${BUILDOBJ}/_.mounted_fat/

# Install FreeBSD's ubldr onto FAT partition.
#
# TODO: This is a binary blob for the moment until I get
#  some local patches committed and find a cleaner way to
#  build and install ubldr.
#
#cp /usr/obj/arm.arm/usr/src/sys/boot/arm/uboot/ubldr ${BUILDOBJ}/_.mounted_fat/
cp files/ubldr ${BUILDOBJ}/_.mounted_fat/

#
# Install FreeBSD kernel and world onto UFS partition.
#
cd $FREEBSD_SRC
echo "Installing FreeBSD kernel onto the UFS partition at "`date`
make TARGET_ARCH=arm TARGET_CPUTYPE=armv6 DESTDIR=${BUILDOBJ}/_.mounted_ufs KERNCONF=${KERNCONF} installkernel > ${BUILDOBJ}/_.installkernel.log 2>&1
echo "Installing FreeBSD world onto the UFS partition at "`date`
make TARGET_ARCH=arm TARGET_CPUTYPE=armv6 DESTDIR=${BUILDOBJ}/_.mounted_ufs installworld > ${BUILDOBJ}/_.installworld.log 2>&1
make TARGET_ARCH=arm TARGET_CPUTYPE=armv6 DESTDIR=${BUILDOBJ}/_.mounted_ufs distrib-dirs > ${BUILDOBJ}/_.distrib-dirs.log 2>&1
make TARGET_ARCH=arm TARGET_CPUTYPE=armv6 DESTDIR=${BUILDOBJ}/_.mounted_ufs distribution > ${BUILDOBJ}/_.distribution.log 2>&1

# Configure FreeBSD
# These could be generated dynamically if we needed.
echo "Configuring FreeBSD at "`date`
mkdir -p ${BUILDOBJ}/_.mounted_ufs/etc
cp ${TOPDIR}/files/rc.conf ${BUILDOBJ}/_.mounted_ufs/etc/
cp ${TOPDIR}/files/fstab ${BUILDOBJ}/_.mounted_ufs/etc/

# Copy source onto card as well.
if [ -n "$INSTALL_USR_SRC" ]; then
    echo "Copying source to /usr/src on disk image at "`date`
    mkdir -p ${BUILDOBJ}/_.mounted_ufs/usr/src
    cd ${BUILDOBJ}/_.mounted_ufs/usr/src
    # Note: Includes the .svn directory.
    (cd $FREEBSD_SRC ; tar cf - .) | tar xpf -
fi

if [ -n "$INSTALL_USR_PORTS" ]; then
    mkdir -p ${BUILDOBJ}/_.mounted_ufs/usr/ports
    echo "Updating ports snapshot at "`date`
    portsnap fetch > ${BUILDOBJ}/_.portsnap.fetch.log
    echo "Installing ports tree at "`date`
    portsnap -p ${BUILDOBJ}/_.mounted_ufs/usr/ports extract > ${BUILDOBJ}/_.portsnap.extract.log
fi

#
# Unmount and clean up.
#
echo "Unmounting the disk image at "`date`
cd $TOPDIR
umount ${BUILDOBJ}/_.mounted_fat
umount ${BUILDOBJ}/_.mounted_ufs
mdconfig -d -u ${MD}

#
# We have a finished image; explain what to do with it.
#
echo "DONE."
echo "Completed disk image is in: ${IMG}"
echo
echo "Copy to a MicroSDHC card using a command such as:"
echo "dd if=${IMG} of=/dev/da0"
echo "(Replace /dev/da0 with the appropriate path for your SDHC card reader.)"
echo
date
