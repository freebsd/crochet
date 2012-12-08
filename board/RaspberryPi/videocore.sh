
videocore_src_check ( ) {
    if [ ! -d $VC_SRC ]; then
	echo "Need VideoCore kernel module code for FreeBSD"
	echo "Use the following command to fetch them:"
	echo
	echo " $ git clone git://github.com/gonzoua/vchiq-freebsd.git ${VC_SRC}"
	echo
	echo "Run this script again after you have the files."
	exit 1
    fi
}

videocore_build ( ) (
    if [ -f ${WORKDIR}/_.built-videocore-module ]
    then
	echo "Using VideoCore kernel module from previous build"
	return 0;
    fi

    echo "Building VideoCore kernel module"
    cd ${FREEBSD_SRC}
    buildenv=`make TARGET_ARCH=$TARGET_ARCH buildenvvars`
    eval $buildenv SYSDIR=${FREEBSD_SRC}/sys MAKESYSPATH=${FREEBSD_SRC}/share/mk make -C ${VC_SRC}

    touch ${WORKDIR}/_.built-videocore-module
)

# $1: Target directory for install
videocore_install ( ) (
    echo "Installing VideoCore kernel module"
    cd ${FREEBSD_SRC}
    buildenv=`make TARGET_ARCH=$TARGET_ARCH buildenvvars`
    eval $buildenv SYSDIR=${FREEBSD_SRC}/sys MAKESYSPATH=${FREEBSD_SRC}/share/mk make -C ${VC_SRC} DESTDIR=$1 install
)

CMAKE=`which cmake`
cmake_check ( ) {
    if [ -z ${CMAKE} ]; then
	echo "VideoCore userland build requires 'cmake'"
	echo "Please install and re-run this script."
	exit 1
    fi
}

videocore_user_check ( ) {
    cmake_check
    if [ ! -d $VC_USER_SRC ]; then
	echo "Need VideoCore user library code for FreeBSD"
	echo "Use the following command to fetch them:"
	echo
	echo " $ git clone -b freebsd git://github.com/gonzoua/userland.git ${VC_USER_SRC}"
	echo
	echo "Run this script again after you have the files."
	exit 1
    fi
}

videocore_user_build ( ) (
    if [ -f ${WORKDIR}/_.built-videocore-library ]
    then
	echo "Using VideoCore user library from previous build"
	return 0;
    fi

    echo "Building VideoCore user library"
    cd ${FREEBSD_SRC}
    buildenv=`make TARGET_ARCH=$TARGET_ARCH buildenvvars`
    _VC_BUILDDIR=${VC_USER_SRC}/build/arm-freebsd/release/
    mkdir -p ${_VC_BUILDDIR}
    cd ${_VC_BUILDDIR}
    # Should the toolchain file be in the board directory?
    # Would that let us use the upstream videocore directly?
    eval $buildenv $CMAKE -DCMAKE_TOOLCHAIN_FILE=${VC_USER_SRC}/makefiles/cmake/toolchains/arm-freebsd.cmake -DCMAKE_BUILD_TYPE=Release ${VC_USER_SRC}
    cd ${_VC_BUILDDIR}
    eval $buildenv make

    touch ${WORKDIR}/_.built-videocore-library
)

# $1: DESTDIR
videocore_user_install ( ) (
    echo "TODO: Install videocore library"
    exit 1
)