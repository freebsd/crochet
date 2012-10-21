#!/bin/sh -e

echo 'Starting at '`date`

# General configuration and useful definitions
TOPDIR=`cd \`dirname $0\`; pwd`
LIBDIR=${TOPDIR}/lib
WORKDIR=${TOPDIR}/work

MB=$((1000 * 1000))
GB=$((1000 * $MB))

# Load builder libraries.
. ${LIBDIR}/base.sh
. ${LIBDIR}/disk.sh
. ${LIBDIR}/freebsd.sh
. ${LIBDIR}/uboot.sh

# Placeholder definitions of functions overridden by board setup.
board_check_prerequisites ( ) {
    freebsd_current_test
}
board_build_bootloader ( ) { }
board_construct_boot_partition ( ) { }
board_customize_freebsd_partition ( ) { }

# Empty definitions of functions to be overridden by user.
customize_boot_partition ( ) { }
customize_freebsd_partition ( ) { }

#
# Load user configuration
#
load_config

# Initialize the work directory, clean out old logs.
mkdir -p ${WORKDIR}
rm -f ${WORKDIR}/*.log

#
# Now we can build the system.
#
board_check_prerequisites
freebsd_buildworld
freebsd_buildkernel
board_build_bootloader
disk_create_image ${IMG} ${SD_SIZE}
disk_partition_mbr
board_construct_boot_partition

#
# TODO: create the swap partition
#
# disk_swap_create <size>

#
# Create, mount, and populate the UFS partition.
#
UFS_MOUNT=${WORKDIR}/_.mounted_ufs
disk_ufs_create
disk_ufs_mount ${UFS_MOUNT}

[ -z "$FREEBSD_INSTALL_KERNEL" ] || freebsd_installkernel ${UFS_MOUNT}


if [ -n "$FREEBSD_INSTALL_WORLD" ]
then
    freebsd_installworld ${UFS_MOUNT}

    [ -z "$INSTALL_USR_SRC" ] || freebsd_install_usr_src
    [ -z "$INSTALL_USR_PORTS" ] || freebsd_install_usr_ports

    if [ -d ${BOARDDIR}/overlay ]
    then
	echo "Overlaying board-specific files from ${BOARDDIR}/overlay"
	(cd ${BOARDDIR}/overlay; find . | cpio -p ${UFS_MOUNT})
    fi
    if [ -d ${WORKDIR}/overlay ]
    then
	echo "Overlaying files from ${WORKDIR}/overlay"
	(cd ${WORKDIR}/overlay; find . | cpio -p ${UFS_MOUNT})
    fi

fi

cd ${UFS_MOUNT}
board_customize_freebsd_partition ${UFS_MOUNT}
customize_freebsd_partition ${UFS_MOUNT}
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
echo "dd if=${IMG} of=/dev/da0 bs=1m"
echo "(Replace /dev/da0 with the appropriate path for your SDHC card reader.)"
echo
date
