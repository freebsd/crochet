#!/bin/sh -e

# General configuration and useful definitions
TOPDIR=`cd \`dirname $0\`; pwd`
LIBDIR=${TOPDIR}/lib
CONFIGDIR=${TOPDIR}/config/arm/BEAGLEBONE
MB=$((1000 * 1000))
GB=$((1000 * $MB))

# Load builder libraries we need.
. ${LIBDIR}/base.sh
. ${LIBDIR}/freebsd.sh
. ${LIBDIR}/freebsd_xdev.sh
. ${LIBDIR}/uboot.sh

#
# Get the config values:
#
load_config


mkdir -p ${BUILDOBJ}
# Why does this have no effect?
MAKEOBJDIRPREFIX=${BUILDOBJ}/_freebsd_build
# Clean out old log files before we start.
rm -f ${BUILDOBJ}/*.log

#
# Check various prerequisites
# Do this all up front so the poor schmuck running this script
# can go get lunch during the lengthy builds that follow.
#

# We need TIs modified U-Boot sources
uboot_ti_test || exit 1

# We need FreeBSD cross-tools for arm
freebsd_xdev_test || exit 1

# We need a FreeBSD source tree with the armv6 changes.
# FreeBSD-CURRENT after r239281
# (We can tell it's the right one by the presence of the BEAGLEBONE configuration file).
if [ \! -f "$FREEBSD_SRC/sys/arm/conf/BEAGLEBONE" ]; then
    echo "Need FreeBSD tree with armv6 support."
    echo "You can obtain this with the folowing command:"
    echo
    echo "mkdir -p $FREEBSD_SRC && svn co http://svn.freebsd.org/base/head $FREEBSD_SRC"
    echo
    echo "If you already have FreeBSD-CURRENT sources in $FREEBSD_SRC, then"
    echo "please verify that it's at least r239281 (15 August 2012)."
    echo
    echo "Edit \$FREEBSD_SRC in beaglebsd-config.sh if you want the sources in a different directory."
    echo "Run this script again after you have the sources installed."
    exit 1
fi
echo "Found suitable FreeBSD source tree in $FREEBSD_SRC"

#
# Patch, configure, and build U-Boot
#
uboot_patch ${CONFIGDIR}/files/uboot_*.patch
uboot_configure am335x_evm_config
uboot_build

#
# Build FreeBSD
#
freebsd_buildworld
freebsd_buildkernel $KERNCONF
freebsd_ubldr_build 0x88000000

#
# Create and partition the disk image
#
# TODO: Figure out how to include a swap partition here.
# Swapping to SD is painful, but not as bad as panicing
# the kernel when you run out of memory.
# TODO: Fix the kernel panics on out-of-memroy.
#
echo "Creating the raw disk image in ${IMG}"
[ -f ${IMG} ] && rm -f ${IMG}
dd if=/dev/zero of=${IMG} bs=1 seek=${SD_SIZE} count=0 >/dev/null 2>&1
MD=`mdconfig -a -t vnode -f ${IMG}`

echo "Partitioning the raw disk image at "`date`
# TI AM335x ROM code requires we use MBR partitioning.
gpart create -s MBR -f x ${MD}
gpart add -a 63 -b 63 -s2m -t '!12' -f x ${MD}
gpart set -a active -i 1 -f x ${MD}
FAT_PART=s1
FAT_DEV=/dev/${MD}${FAT_PART}
gpart add -t freebsd -f x ${MD}
UFS_PART=s2
UFS_DEV=/dev/${MD}${UFS_PART}
gpart commit ${MD}

echo "Formatting the FAT partition at "`date`
# TODO: Select FAT12, FAT16, or FAT32 depending on the size of the partition.
newfs_msdos -L "boot" -F 12 ${FAT_DEV} >/dev/null

#
# Mount the FAT partition
#
echo "Mounting the virtual FAT partition"
if [ -d ${BUILDOBJ}/_.mounted_fat ]; then
    # Note:  _.mounted_fat should only exist if the partition
    # is actually mounted.
    umount ${BUILDOBJ}/_.mounted_fat || true
    rmdir ${BUILDOBJ}/_.mounted_fat
fi
mkdir ${BUILDOBJ}/_.mounted_fat
mount_msdosfs ${FAT_DEV} ${BUILDOBJ}/_.mounted_fat

# Install U-Boot onto FAT partition.
echo "Installing U-Boot onto the FAT partition at "`date`
cp ${UBOOT_SRC}/MLO ${BUILDOBJ}/_.mounted_fat/
cp ${UBOOT_SRC}/u-boot.img ${BUILDOBJ}/_.mounted_fat/
cp ${CONFIGDIR}/files/uEnv.txt ${BUILDOBJ}/_.mounted_fat/

# Install ubldr onto FAT partition.
freebsd_ubldr_copy ${BUILDOBJ}/_.mounted_fat/

#
# Unmount FAT partition
#
echo "Unmounting FAT partition"
umount ${BUILDOBJ}/_.mounted_fat
rmdir ${BUILDOBJ}/_.mounted_fat

#
# Format and mount the UFS partition
#

echo "Formatting the UFS partition at "`date`
newfs ${UFS_DEV} >/dev/null
# Turn on Softupdates
tunefs -n enable ${UFS_DEV}
# Turn on SUJ with a minimally-sized journal.
# This makes reboots tolerable if you just pull power on the BB
# Note:  A slow SDHC reads about 1MB/s, so a 30MB
# journal can delay boot by 30s.
tunefs -j enable -S 4194304 ${UFS_DEV}
# Turn on NFSv4 ACLs
tunefs -N enable ${UFS_DEV}


echo "Mounting UFS partition"
if [ -d ${BUILDOBJ}/_.mounted_ufs ]; then
    umount ${BUILDOBJ}/_.mounted_ufs || true
    rmdir ${BUILDOBJ}/_.mounted_ufs
fi
mkdir ${BUILDOBJ}/_.mounted_ufs
mount ${UFS_DEV} ${BUILDOBJ}/_.mounted_ufs


#
# Install FreeBSD kernel and world onto UFS partition.
#
freebsd_installkernel ${BUILDOBJ}/_.mounted_ufs
freebsd_installworld ${BUILDOBJ}/_.mounted_ufs

# Copy configuration files
echo "Configuring FreeBSD at "`date`
cd ${CONFIGDIR}/overlay
find . | cpio -p ${BUILDOBJ}/_.mounted_ufs

# If requested, copy source onto card as well.
if [ -n "$INSTALL_USR_SRC" ]; then
    freebsd_install_usr_src ${BUILDOBJ}/_.mounted_ufs
fi

# If requested, install a ports tree.
if [ -n "$INSTALL_USR_PORTS" ]; then
    freebsd_install_usr_ports ${BUILDOBJ}/_.mounted_ufs
fi

# Done with UFS partition.
echo "Unmounting the UFS partition at "`date`
cd $TOPDIR
umount ${BUILDOBJ}/_.mounted_ufs
rmdir ${BUILDOBJ}/_.mounted_ufs

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
