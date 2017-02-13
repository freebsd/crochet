#
PHASE_FREEBSD_NANOBSD_INSTALL=780

#
NANO_DEV="/dev/mmcsd0"
if [ -n "$1" ]; then
    NANO_DEV="$1"
fi

#
NANO_OS_SIZE="-s 1g"
if [ -n "$2" ]; then
    NANO_OS_SIZE="-s $2"
fi

#
NANO_OS_COUNT=2
if [ -n "$3" ]; then
    if [ "$3" -lt 1 -o "$3" -gt 2 ]; then
        echo "Only 1 or 2 OS partitions are allowed"
        exit 1
    fi
    NANO_OS_COUNT="$3"
fi

#
NANO_CFG_SIZE="-s 32m"
if [ -n "$4" ]; then
    NANO_CFG_SIZE="-s $4"
fi


#
disk_ufs_create() {
    local NEW_UFS_SLICE
    local NEW_UFS_SLICE_NUMBER

    echo "Creating the NanoBSD style UFS partitions at "`date`

    NEW_UFS_SLICE=`gpart add -t freebsd ${DISK_MD} | sed -e 's/ .*//'` || exit 1
    NEW_UFS_SLICE_NUMBER=`echo ${NEW_UFS_SLICE} | sed -e 's/.*[^0-9]//'`

    #
    gpart create -s BSD ${NEW_UFS_SLICE}

    # OS Partitions
    OSA_UFS_PARTITION=`gpart add -t freebsd-ufs ${NANO_OS_SIZE} ${NEW_UFS_SLICE} | sed -e 's/ .*//'` || exit 1
    OSA_UFS_DEVICE=/dev/${OSA_UFS_PARTITION}
    newfs ${OSA_UFS_DEVICE}

    disk_created_new UFS ${OSA_UFS_PARTITION}

    OSB_UFS_PARTITION=`gpart add -t freebsd-ufs ${NANO_OS_SIZE} ${NEW_UFS_SLICE} | sed -e 's/ .*//'` || exit 1

    # CFG Paritition
    #CFG_UFS_PARTITION=`gpart add -t freebsd-ufs ${NANO_CFG_SIZE} -l cfg ${NEW_UFS_SLICE} | sed -e 's/ .*//'` || exit 1
    CFG_UFS_PARTITION=`gpart add -t freebsd-ufs -i 4 ${NANO_CFG_SIZE} ${NEW_UFS_SLICE} | sed -e 's/ .*//'` || exit 1
    CFG_UFS_DEVICE=/dev/${CFG_UFS_PARTITION}
    newfs ${CFG_UFS_DEVICE}

    # DATA Paritition
    #DATA_UFS_PARTITION=`gpart add -t freebsd-ufs -l data ${NEW_UFS_SLICE} | sed -e 's/ .*//'` || exit 1
    DATA_UFS_PARTITION=`gpart add -t freebsd-ufs -i 5 ${NEW_UFS_SLICE} | sed -e 's/ .*//'` || exit 1
    DATA_UFS_DEVICE=/dev/${DATA_UFS_PARTITION}
    newfs ${DATA_UFS_DEVICE}
    tunefs -n enable ${DATA_UFS_DEVICE}			# Turn on Softupdates
    tunefs -j enable -S 4194304 ${DATA_UFS_DEVICE}      # Turn on SUJ with a minimally-sized journal
    tunefs -N enable ${DATA_UFS_DEVICE}                 # Turn on NFSv4 ACLs
}


#
nanobsd_install() {
    (
    cd ${BOARD_FREEBSD_MOUNTPOINT}

    # move /usr/local/etc into /etc/local and create symlink
    mkdir -p etc/local
    if [ -d usr/local/etc ]; then
        (
        cd usr/local/etc
        find . -print | cpio -dumpl -R root:wheel ../../../etc/local
        cd ..
        rm -fr ./etc
        ln -s ../../etc/local ./etc
        )
    fi

    # force diskless mode
    touch etc/diskless
    chown root:wheel etc/diskless

    # mount root filesystem readonly
    echo "root_rw_mount=NO" >> etc/defaults/rc.conf
    chown root:wheel etc/defaults/rc.conf

    # add /cfg and /data to /etc/fstab
    cp /dev/null etc/fstab
    echo "${NANO_DEV}s2a /            ufs      ro                 1 1" >> etc/fstab
    echo "${NANO_DEV}s2d /cfg         ufs      rw,noatime,noauto  2 2" >> etc/fstab
    echo "${NANO_DEV}s2e /data        ufs      rw,noatime         2 2" >> etc/fstab
    chown root:wheel etc/fstab

    # create mount points for extra filesystems
    mkdir -p cfg
    mkdir -p data

    # create /conf/etc and /conf/var
    for d in var etc
    do
        mkdir -p conf/base/$d conf/default/$d
        find $d -print | cpio -dumpl -R root:wheel conf/base/
    done
    #chown -Rh root:wheel conf/base
    chgrp operator conf/base/etc/dumpdates

    if [ -z ${NANO_RAM_ETCSIZE} ]; then
    	NANO_RAM_ETCSIZE=10240
    fi
    if [ -z ${NANO_RAM_VARSIZE} ]; then
    	NANO_RAM_VARSIZE=32768
    fi

    echo "${NANO_RAM_ETCSIZE}" > conf/base/etc/md_size
    echo "${NANO_RAM_VARSIZE}" > conf/base/var/md_size
    chown root:wheel conf/base/etc/md_size
    chown root:wheel conf/base/var/md_size

    echo "mount -o ro ${NANO_DEV}s2d" > conf/default/etc/remount
    chown root:wheel conf/default/etc/remount

    echo "NANO_DRIVE=${NANO_DEV}" > etc/nanobsd.conf
    )
}


#
nanobsd_overlay() {
  if [ -d ${TOPDIR}/option/NanoBSD/overlay ]; then
    echo "Overlaying files from ${TOPDIR}/option/NanoBSD/overlay"
    (cd ${TOPDIR}/option/NanoBSD/overlay; find . | cpio -pmud -R root:wheel ${BOARD_FREEBSD_MOUNTPOINT})
  fi
}

strategy_add $PHASE_FREEBSD_NANOBSD_INSTALL nanobsd_overlay
strategy_add $PHASE_FREEBSD_NANOBSD_INSTALL nanobsd_install
