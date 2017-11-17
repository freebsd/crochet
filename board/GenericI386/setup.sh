TARGET_ARCH=i386
KERNCONF=GENERIC
IMAGE_SIZE=$((600 * 1000 * 1000))

generic_i386_partition_image ( ) { 
        # basic setup
        disk_partition_mbr
        disk_ufs_create

        # boot loader	
        echo "Installing bootblocks"

	# TODO: This is broken; should use 'make install' to copy
	# bootfiles to workdir, then install to disk image from there.
        BOOTFILES=${FREEBSD_OBJDIR}/stand/i386
        echo "Boot files are at: "${BOOTFILES} 
        gpart bootcode -b ${BOOTFILES}/mbr/mbr ${DISK_MD} || exit 1
        gpart set -a active -i 1 ${DISK_MD} || exit 1
        gpart bootcode -b ${BOOTFILES}/boot2/boot ${DISK_MD}s1 || exit 1

        #show the disk
        gpart show ${DISK_MD}
}

strategy_add $PHASE_PARTITION_LWW generic_i386_partition_image

# Kernel installs in UFS partition
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
