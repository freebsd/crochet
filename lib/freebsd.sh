FREEBSD_SRC=/usr/src
TARGET_ARCH=armv6
WORLDJOBS=4

freebsd_download_instructions ( ) {
    echo "Need FreeBSD tree with armv6 support."
    echo "You can obtain this with the folowing command:"
    echo
    echo "mkdir -p $FREEBSD_SRC && svn co http://svn.freebsd.org/base/head $FREEBSD_SRC"
    echo
    echo "If you already have FreeBSD-CURRENT sources in $FREEBSD_SRC, then"
    echo "please verify that it's at least r239281 (15 August 2012)."
    echo
    echo "Edit \$FREEBSD_SRC in beaglebsd-config.sh if you want the sources in a different directory."
    echo "Run this script again after you have the sources installed."
}

# freebsd_src_test: Check FreeBSD src tree
#
# $1: Name of kernel configuration
#
freebsd_src_test ( ) {
    # TODO: check that it's a FreeBSD source tree first
    if [ \! -f "$FREEBSD_SRC/sys/arm/conf/$1" ]; then
	# TODO: Change the message here to indicate that
	# the kernel config wasn't found.
	freebsd_download_instructions
	exit 1
    fi
    echo "Found suitable FreeBSD source tree in $FREEBSD_SRC"
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
    make TARGET_ARCH=$TARGET_ARCH DEBUG_FLAGS=-g -j $WORLDJOBS buildworld > ${WORKDIR}/_.buildworld.log 2>&1 && touch ${WORKDIR}/_.built-world
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
    make TARGET_ARCH=$TARGET_ARCH "$@" -j $KERNJOBS buildkernel > ${WORKDIR}/_.buildkernel.log 2>&1 && touch ${WORKDIR}/_.built-kernel
}

# freebsd_installworld: Install FreeBSD world to image
#
# $1: Root directory of UFS partition
#
freebsd_installworld ( ) {
    # TODO: check and warn if world isn't built.
    cd $FREEBSD_SRC
    echo "Installing FreeBSD world onto the UFS partition at "`date`
    make TARGET_ARCH=$TARGET_ARCH DEBUG_FLAGS=-g DESTDIR=$1 installworld > ${WORKDIR}/_.installworld.log 2>&1
    make TARGET_ARCH=$TARGET_ARCH DESTDIR=$1 distrib-dirs > ${WORKDIR}/_.distrib-dirs.log 2>&1
    make TARGET_ARCH=$TARGET_ARCH DESTDIR=$1 distribution > ${WORKDIR}/_.distribution.log 2>&1
}

# freebsd_installkernel: Install FreeBSD kernel to image
#
# $1: Root directory of UFS partition
#
freebsd_installkernel ( ) {
    # TODO: check and warn if kernel isn't built.
    cd $FREEBSD_SRC
    echo "Installing FreeBSD kernel onto the UFS partition at "`date`
    make TARGET_ARCH=$TARGET_ARCH DESTDIR=$1 KERNCONF=${KERNCONF} installkernel > ${WORKDIR}/_.installkernel.log 2>&1
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
