#!/bin/sh -e

echo 'Starting at '`date`

# General configuration and useful definitions
TOPDIR=`cd \`dirname $0\`; pwd`
LIBDIR=${TOPDIR}/lib
CONFIGDIR=${TOPDIR}/config/arm/BEAGLEBONE
MB=$((1000 * 1000))
GB=$((1000 * $MB))

# Load builder libraries we need.
. ${LIBDIR}/base.sh
. ${LIBDIR}/freebsd.sh
. ${LIBDIR}/uboot.sh

# TODO: Parameter parsing?

# Load user configuration
load_config

# Initialize the work directory, clean out old logs.
mkdir -p ${WORKDIR}
rm -f ${WORKDIR}/*.log

#
# Check prerequisites
#
uboot_ti_test   # TIs modified U-Boot sources
freebsd_src_test $KERNCONF

#
# Patch, configure, and build U-Boot
#
uboot_patch ${CONFIGDIR}/files/uboot_*.patch
uboot_configure am335x_evm_config
uboot_build

#
# Build FreeBSD and ubldr
#
freebsd_buildworld
freebsd_buildkernel KERNCONF=$KERNCONF
freebsd_ubldr_build UBLDR_LOADADDR=0x88000000

#
# Create and partition the disk image
#
disk_create_image ${IMG} ${SD_SIZE}
disk_partition_mbr

#
# Format, mount, and populate the FAT partition
#
FAT_MOUNT=${WORKDIR}/_.mounted_fat
disk_fat_format
disk_fat_mount ${FAT_MOUNT}

echo "Installing U-Boot onto the FAT partition"
cp ${UBOOT_SRC}/MLO ${FAT_MOUNT}
cp ${UBOOT_SRC}/u-boot.img ${FAT_MOUNT}
cp ${CONFIGDIR}/files/uEnv.txt ${FAT_MOUNT}

freebsd_ubldr_copy ${FAT_MOUNT}

disk_fat_unmount ${FAT_MOUNT}
unset FAT_MOUNT

#
# Format, mount, and populate the UFS partition
#
UFS_MOUNT=${WORKDIR}/_.mounted_ufs
disk_ufs_format
disk_ufs_mount ${UFS_MOUNT}

freebsd_installkernel ${UFS_MOUNT}
freebsd_installworld ${UFS_MOUNT}

echo "Configuring FreeBSD at "`date`
cd ${CONFIGDIR}/overlay
find . | cpio -p ${UFS_MOUNT}

[ -z "$INSTALL_USR_SRC" ] || freebsd_install_usr_src ${UFS_MOUNT}
[ -z "$INSTALL_USR_PORTS" ] || freebsd_install_usr_ports ${UFS_MOUNT}

disk_ufs_unmount ${UFS_MOUNT}
unset UFS_MOUNT

#
# Clean up the virtual disk machinery.
#
disk_release_image

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
