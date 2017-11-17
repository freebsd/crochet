TARGET_ARCH=i386
KERNCONF=ALIX
IMAGE_SIZE=$((1024 * 1000 * 1000))

# copy the build config
alix_copy_buildconfig ( ) {
        KERNEL_CONFIG_FILE="ALIX${FREEBSD_MAJOR_VERSION}"
        echo "Copying build config ${KERNEL_CONFIG_FILE} to source tree"
        cp ${BOARDDIR}/conf/${KERNEL_CONFIG_FILE} ${FREEBSD_SRC}/sys/i386/conf/${KERNCONF}
}

strategy_add $PHASE_POST_CONFIG alix_copy_buildconfig

# create a MBR disk with a single UFS partition
# based on instructions here: http://www.wonkity.com/~wblock/docs/html/disksetup.html
#
alix_partition_image ( ) {
        # basic setup
        disk_partition_mbr
        disk_ufs_create

        # boot loader
        echo "Installing bootblocks"

        # TODO: This is broken; should use 'make install' to copy
        # bootfiles to workdir, then install to disk image from there.

        BOOTFILES=${FREEBSD_OBJDIR}/stand/i386
        echo "Boot files are at: "${BOOTFILES}

        echo " gpart bootcode -b ${BOOTFILES}/mbr/mbr ${DISK_MD}"
        gpart bootcode -b ${BOOTFILES}/mbr/mbr ${DISK_MD} || exit 1

        echo " gpart set -a active -i 1 ${DISK_MD}"
        gpart set -a active -i 1 ${DISK_MD} || exit 1

        echo " gpart bootcode -b ${BOOTFILES}/boot2/boot ${DISK_MD}s1"
        gpart bootcode -b ${BOOTFILES}/boot2/boot ${DISK_MD}s1 || exit 1

        #show the disk
        gpart show ${DISK_MD}
}

strategy_add $PHASE_PARTITION_LWW alix_partition_image

# Kernel installs in UFS partition
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .


