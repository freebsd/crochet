RPI_VC_USER_SRC=${TOPDIR}/vcuserland

CMAKE=`which cmake`
videocore_cmake_check ( ) {
    if [ -z ${CMAKE} ]; then
	echo "VideoCore userland build requires 'cmake'"
	echo "Please install devel/cmake and re-run this script."
	exit 1
    fi
}
strategy_add $PHASE_CHECK videocore_cmake_check

videocore_user_src_check ( ) {
    if [ ! -d $RPI_VC_USER_SRC ]; then
	echo "Need VideoCore user library code for FreeBSD"
	echo "Use the following command to fetch them:"
	echo
	echo " $ git clone -b freebsd git://github.com/gonzoua/userland.git ${RPI_VC_USER_SRC}"
	echo
	echo "Run this script again after you have the files."
	rm -f ${WORKDIR}/_.built-videocore-library
	exit 1
    fi
}
strategy_add $PHASE_CHECK videocore_user_src_check

videocore_user_build ( ) {
    if [ -f ${WORKDIR}/_.built-videocore-library ]
    then
	echo "Using VideoCore user library from previous build"
	return 0;
    fi

    echo "Building VideoCore user library"
    cd ${FREEBSD_SRC}
    buildenv=`make TARGET_ARCH=$TARGET_ARCH buildenvvars`
    _VC_BUILDDIR=${RPI_VC_USER_SRC}/build/arm-freebsd/release/
    mkdir -p ${_VC_BUILDDIR}
    cd ${_VC_BUILDDIR}
    # Should the toolchain file be in the board directory?
    # Would that let us use the upstream videocore directly?
    log=${WORKDIR}/_.videocore-userland.log
    cmd="$buildenv $CMAKE -DCMAKE_TOOLCHAIN_FILE=${RPI_VC_USER_SRC}/makefiles/cmake/toolchains/arm-freebsd.cmake -DCMAKE_BUILD_TYPE=Release ${RPI_VC_USER_SRC}"
    echo $cmd > $log
    if eval $cmd >> $log 2>&1; then
	true
    else
	echo "Failed to configure VideoCore user library."
	echo "Log file:"
	echo "   $log"
	exit 1
    fi
    cd ${_VC_BUILDDIR}
    if eval $buildenv make >> $log 2>&1; then
	touch ${WORKDIR}/_.built-videocore-library
    else
	echo "Failed to build VideoCore user library."
	echo "Log file:"
	echo "   $log"
	exit 1
    fi
}
strategy_add $PHASE_BUILD_OTHER videocore_user_build

# cwd: DESTDIR
videocore_user_install ( ) {
    cd ${FREEBSD_SRC}
    buildenv=`make TARGET_ARCH=$TARGET_ARCH buildenvvars`
    _VC_BUILDDIR=${RPI_VC_USER_SRC}/build/arm-freebsd/release/
    DESTDIR=${BOARD_FREEBSD_MOUNTPOINT}

    eval $buildenv make -C ${_VC_BUILDDIR} DESTDIR=${DESTDIR} install
    echo /opt/vc/lib > ${DESTDIR}/etc/ld-elf.so.conf
}
strategy_add $PHASE_FREEBSD_BOARD_INSTALL videocore_user_install

# hello_triangle demo, not really necessary
videocore_user_install_demo ( ) {
    cd ${FREEBSD_SRC}
    buildenv=`make TARGET_ARCH=$TARGET_ARCH buildenvvars`
    DESTDIR=${BOARD_FREEBSD_MOUNTPOINT}

    cd ${RPI_VC_USER_SRC}/host_applications/linux/apps/hello_pi/hello_triangle
    eval $buildenv SDKSTAGE=${DESTDIR} gmake
    cp hello_triangle.bin *.raw ${DESTDIR}/root
}
strategy_add $PHASE_FREEBSD_BOARD_INSTALL videocore_user_install_demo
