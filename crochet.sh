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
. ${LIBDIR}/board.sh

# Empty definitions of functions to be overridden by user.
# Goal:  config.sh should never need to override any of the
# shell functions defined by the board or library routines.
customize_boot_partition ( ) { }
customize_freebsd_partition ( ) { }
customize_post_unmount ( ) { }

handle_trap ( ) {
    echo "Abort requested!"
    disk_unmount_all
    exit
}
trap handle_trap INT QUIT KILL EXIT

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

#
# Create and partition the image(s)
#
board_create_image ${IMG} ${SD_SIZE}
board_partition_image
board_mount_partitions

#
# Populate the partitions and run the user customization routines.
#
board_populate_boot_partition
board_populate_freebsd_partition

if cd ${BOARD_BOOT_MOUNTPOINT}; then
    customize_boot_partition ${BOARD_BOOT_MOUNTPOINT}
else
    echo "Skipping customize_boot_partition, since there isn't one."
fi
if cd ${BOARD_FREEBSD_MOUNTPOINT}; then
    customize_freebsd_partition ${BOARD_FREEBSD_MOUNTPOINT}
else
    echo "This is bad: there is no FreeBSD mountpoint."
    exit 1
fi
cd ${TOPDIR}

# Unmount all the partitions, clean up the MD node, etc.
disk_unmount_all

# Some people might need to play games with partitions after they're
# unmounted.  (E.g., NanoBSD-style duplicate partitions or tunefs.)
board_post_unmount ${IMG} # For board to override
customize_post_unmount ${IMG} # For config.sh to override

#
# We have a finished image; explain what to do with it.
#
board_show_message
date
