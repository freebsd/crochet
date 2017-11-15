
# Clean out any old i386 boot bits.
rm -rf ${WORKDIR}/boot
mkdir -p ${WORKDIR}/boot/defaults

#
# Note that the 'build' functions here all do a fake 'install' to
# ${WORKDIR}/boot so we can copy single files to the final image
# without having to hardcode deep paths into the FreeBSD source or
# object tree.
#
generic_i386_build_mbr ( ) {
    echo "Building MBR"
    cd ${FREEBSD_SRC}
    buildenv=`make -C ${FREEBSD_SRC} TARGET_ARCH=${TARGET_ARCH} buildenvvars`
    cd stand/i386/mbr
    if eval ${buildenv} make > ${WORKDIR}/_.i386.mbr.log 2>&1
    then
    true
    else
    echo "Failed to build MBR:"
    tail ${WORKDIR}/_.i386.mbr.log
    exit 1
    fi
    eval ${buildenv} make DESTDIR=${WORKDIR} install || exit 1
}
strategy_add $PHASE_BUILD_OTHER generic_i386_build_mbr

generic_i386_build_boot2 ( ) {
    echo "Building Boot2"
    cd ${FREEBSD_SRC}
        buildenv=`make -C ${FREEBSD_SRC} TARGET_ARCH=${TARGET_ARCH} buildenvvars`
    cd stand/i386/boot2
    if eval ${buildenv} make > ${WORKDIR}/_.i386.boot2.log 2>&1
    then
    true
    else
    echo "Failed to build boot2:"
    tail ${WORKDIR}/_.i386.boot2.log
    exit 1
    fi
    eval ${buildenv} make DESTDIR=${WORKDIR} install || exit 1
}
strategy_add $PHASE_BUILD_OTHER generic_i386_build_boot2

generic_i386_build_loader ( ) {
    echo "Building Loader"
    cd ${FREEBSD_SRC}
    export MAKESYSPATH=${FREEBSD_SRC}/share/mk
    buildenv=`make TARGET_ARCH=${TARGET_ARCH} buildenvvars`
    cd stand/i386/loader
    if eval ${buildenv} make > ${WORKDIR}/_.i386_loader_build.log 2>&1
    then
    true
    else
    echo "Failed to build i386 loader:"
    tail ${WORKDIR}/_.i386_loader_build.log
    exit 1
    fi
    if eval ${buildenv} make DESTDIR=${WORKDIR} MK_MAN=no install > ${WORKDIR}/_.i386_loader_install.log 2>&1
    then
    true
    else
    echo "Failed to copy i386 loader into WORKDIR:"
    tail ${WORKDIR}/_.i386_loader_install.log
    exit 1
    fi

}
strategy_add $PHASE_BUILD_OTHER generic_i386_build_loader

# Even though there's only the default partition, we have
# to do extra work here to set all the boot bits.
# DISK_MD is set by the helper functions in lib/disk.sh.
generic_i386_partition_image ( ) {
    disk_partition_mbr
    disk_ufs_create
    echo "Installing bootblocks"
    gpart bootcode -b ${WORKDIR}/boot/mbr ${DISK_MD} || exit 1
    gpart set -a active -i 1 ${DISK_MD} || exit 1
    bsdlabel -B -b ${WORKDIR}/boot/boot `disk_ufs_slice` || exit 1
}
strategy_add $PHASE_PARTITION_LWW generic_i386_partition_image

