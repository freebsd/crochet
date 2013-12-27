TARGET_ARCH=i386
KERNCONF=SOEKRIS
IMAGE_SIZE=$((1024 * 1000 * 1000))

# copy the build config
soekris_copy_buildconfig ( ) {
	KERNEL_CONFIG_FILE="SOEKRIS${FREEBSD_MAJOR_VERSION}"
        echo "Copying build config ${KERNEL_CONFIG_FILE} to source tree"
        cp ${BOARDDIR}/conf/${KERNEL_CONFIG_FILE} ${FREEBSD_SRC}/sys/i386/conf/${KERNCONF}
}

strategy_add $PHASE_POST_CONFIG soekris_copy_buildconfig

# create a MBR disk with a single UFS partition
# based on instructions here: http://www.wonkity.com/~wblock/docs/html/disksetup.html
#
soekris_partition_image ( ) {
        # basic setup
        disk_partition_mbr
        disk_ufs_create

        # boot loader
        echo "Installing bootblocks"
	# TODO: This is broken; should use 'make install' to copy
	# bootfiles to workdir, then install to disk image from there.
        BOOTFILES=${FREEBSD_OBJDIR}sys/boot/i386
        echo "Boot files are at: "${BOOTFILES}
        gpart bootcode -b ${BOOTFILES}/mbr/mbr ${DISK_MD} || exit 1
        gpart set -a active -i 1 ${DISK_MD} || exit 1
        bsdlabel -B -b ${BOOTFILES}/boot2/boot ${DISK_UFS_PARTITION} || exit 1

        #show the disk
        gpart show ${DISK_MD}
}

strategy_add $PHASE_PARTITION_LWW soekris_partition_image

# Kernel installs in UFS partition
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .


