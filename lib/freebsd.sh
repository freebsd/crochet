FREEBSD_SRC=/usr/src
TARGET_ARCH=armv6
WORLDJOBS=4
KERNJOBS=4

freebsd_download_instructions ( ) {
    echo
    echo "You can obtain a suitable FreeBSD source tree with the folowing commands:"
    echo
    echo " $ mkdir -p $FREEBSD_SRC"
    for l in "$@"; do
        echo "$l"
    done
    echo
    echo "Set \$FREEBSD_SRC in config.sh if you have the sources in a different directory."
    echo "Run this script again after you have the sources installed."
    exit 1
}

# freebsd_src_test: Check FreeBSD src tree
#
# $1: Name of kernel configuration
#
freebsd_src_test ( ) {
    # TODO: check that it's a FreeBSD source tree first
    if [ \! -f "$FREEBSD_SRC/sys/arm/conf/$1" ]; then
	echo "Didn't find $FREEBSD_SRC/sys/arm/conf/$1"
	shift
	# TODO: Change the message here to indicate that
	# the kernel config wasn't found.
	freebsd_download_instructions "$@"
	exit 1
    fi
    echo "Found suitable FreeBSD source tree in $FREEBSD_SRC"
}

# freebsd_current_test:  Check that FreeBSD-CURRENT sources are available
# (Specialized version of freebsd_src_test for the common case.)
freebsd_current_test ( ) {
    freebsd_src_test \
	${KERNCONF} \
 	" $ svn co http://svn.freebsd.org/base/head $FREEBSD_SRC"
}

# freebsd_buildworld: Build FreeBSD world.
#
freebsd_buildworld ( ) {
    if [ -f ${WORKDIR}/_.built-world ]; then
	echo "Using FreeBSD world from previous build"
	return 0
    fi

    echo "Building FreeBSD-$TARGET_ARCH world at "`date`" (Logging to ${WORKDIR}/_.buildworld.log)"
    cd $FREEBSD_SRC
    if make TARGET_ARCH=$TARGET_ARCH DEBUG_FLAGS=-g -j $WORLDJOBS buildworld > ${WORKDIR}/_.buildworld.log 2>&1 && touch ${WORKDIR}/_.built-world; then
	# success
    else
	echo "Failed to build FreeBSD world."
	echo "Log in ${WORKDIR}/_.buildworld.log"
	exit 1
    fi
}

# freebsd_buildkernel: Build FreeBSD kernel if it's not already built.
# Note: Assumes world is already built.
#
# $@: arguments to make.  KERNCONF=FOO is required
#
# TODO: save "$@" in _.built-kernel so we can verify that
# the kernel we last built is the same as the one we're being
# asked to build.
#
freebsd_buildkernel ( ) {
    if [ -f ${WORKDIR}/_.built-kernel ]; then
	echo "Using FreeBSD kernel from previous build"
	return 0
    fi

    echo "Building FreeBSD-armv6 kernel at "`date`" (Logging to ${WORKDIR}/_.buildkernel.log)"
    cd $FREEBSD_SRC
    if make TARGET_ARCH=$TARGET_ARCH "$@" -j $KERNJOBS buildkernel > ${WORKDIR}/_.buildkernel.log 2>&1 && touch ${WORKDIR}/_.built-kernel; then
	# success
    else
	echo "Failed to build FreeBSD kernel"
	echo "Log: ${WORKDIR}/_.buildkernel.log"
	exit 1
    fi

}

# freebsd_installworld: Install FreeBSD world to image
#
# $1: Root directory of UFS partition
#
freebsd_installworld ( ) {
    # TODO: check and warn if world isn't built.
    cd $FREEBSD_SRC
    echo "Installing FreeBSD world onto the UFS partition at "`date`
    if make TARGET_ARCH=$TARGET_ARCH DEBUG_FLAGS=-g DESTDIR=$1 installworld > ${WORKDIR}/_.installworld.log 2>&1
    then
	# success
    else
	echo "Installworld failed."
	echo "Log: ${WORKDIR}/_.installworld.log"
	exit 1
    fi

    if make TARGET_ARCH=$TARGET_ARCH DESTDIR=$1 distrib-dirs > ${WORKDIR}/_.distrib-dirs.log 2>&1
    then
	# success
    else
	echo "distrib-dirs failed"
	echo "Log: ${WORKDIR}/_.distrib-dirs.log"
	exit 1
    fi

    if make TARGET_ARCH=$TARGET_ARCH DESTDIR=$1 distribution > ${WORKDIR}/_.distribution.log 2>&1
    then
	# success
    else
	echo "distribution failed"
	echo "Log: ${WORKDIR}/_.distribution.log"
	exit 1
    fi
}

# freebsd_installkernel: Install FreeBSD kernel to image
#
# $1: Root directory of UFS partition
#
freebsd_installkernel ( ) {
    # TODO: check and warn if kernel isn't built.
    cd $FREEBSD_SRC
    echo "Installing FreeBSD kernel onto the UFS partition at "`date`
    if make TARGET_ARCH=$TARGET_ARCH DESTDIR=$1 KERNCONF=${KERNCONF} installkernel > ${WORKDIR}/_.installkernel.log 2>&1
    then
	# success
    else
	echo "installkernel failed"
	echo "Log: ${WORKDIR}/_.installkernel.log"
	exit 1
    fi

}

# freebsd_ubldr_build:  Build the ubldr loader program.
# Note: Assumes world is already built.
#
# $@: make arguments for building
#
freebsd_ubldr_build ( ) {
    if [ -f ${WORKDIR}/ubldr/ubldr ]; then
	echo "Using FreeBSD ubldr from previous build"
	return 0
    fi

    echo "Building FreeBSD $TARGET_ARCH ubldr"
    rm -rf ${WORKDIR}/ubldr
    mkdir -p ${WORKDIR}/ubldr

    cd ${FREEBSD_SRC}
    ubldr_makefiles=`pwd`/share/mk
    buildenv=`make TARGET_ARCH=$TARGET_ARCH buildenvvars`
    cd sys/boot
    eval $buildenv make -m $ubldr_makefiles obj > ${WORKDIR}/_.ubldr.build.log
    eval $buildenv make -m $ubldr_makefiles depend >> ${WORKDIR}/_.ubldr.build.log
    eval $buildenv make "$@" -m $ubldr_makefiles all >> ${WORKDIR}/_.ubldr.build.log
    cd arm/uboot
    eval $buildenv make DESTDIR=${WORKDIR}/ubldr/ BINDIR= NO_MAN=true -m $ubldr_makefiles install >> ${WORKDIR}/_.ubldr.build.log
}

# freebsd_ubldr_copy:  Copy the compiled ubldr files
# to the specified directory.
#
# $1: Target directory to receive ubldr files
#
freebsd_ubldr_copy ( ) {
    echo "Installing ubldr"
    cp ${WORKDIR}/ubldr/ubldr $1
    cp ${WORKDIR}/ubldr/loader.help $1
}

# freebsd_install_usr_src:  Copy FREEBSD_SRC tree
# to /usr/src in image.
#
# $1: root of image
#
freebsd_install_usr_src ( ) {
    echo "Copying source to /usr/src on disk image at "`date`
    mkdir -p $1/usr/src
    cd $1/usr/src
    # Note: Includes the .svn directory.
    (cd $FREEBSD_SRC ; tar cf - .) | tar xpf -
}

# freebsd_install_usr_ports:  Download and install
# a /usr/ports tree to the image.
#
# $1:  root of image
#
freebsd_install_usr_ports ( ) {
    mkdir -p $1/usr/ports
    echo "Updating ports snapshot at "`date`
    portsnap fetch > ${WORKDIR}/_.portsnap.fetch.log
    echo "Installing ports tree at "`date`
    portsnap -p $1/usr/ports extract > ${WORKDIR}/_.portsnap.extract.log
}
