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
    if [ ! -f ${BUILDOBJ}/_.built-world ]; then
	echo "Building FreeBSD-$TARGET_ARCH world at "`date`" (Logging to ${BUILDOBJ}/_.buildworld.log)"
	cd $FREEBSD_SRC
	make TARGET_ARCH=$TARGET_ARCH DEBUG_FLAGS=-g -j $WORLDJOBS buildworld > ${BUILDOBJ}/_.buildworld.log 2>&1
	cd $TOPDIR
	touch ${BUILDOBJ}/_.built-world
    else
	echo "Using FreeBSD world from previous build"
    fi
}

# freebsd_buildkernel: Build FreeBSD kernel
#
# $1: Name of kernel configuration
#
freebsd_buildkernel ( ) {
    if [ ! -f ${BUILDOBJ}/_.built-kernel ]; then
	echo "Building FreeBSD-armv6 kernel at "`date`" (Logging to ${BUILDOBJ}/_.buildkernel.log)"
	cd $FREEBSD_SRC
	make TARGET_ARCH=$TARGET_ARCH KERNCONF=$1 -j $KERNJOBS buildkernel > ${BUILDOBJ}/_.buildkernel.log 2>&1
	cd $TOPDIR
	touch ${BUILDOBJ}/_.built-kernel
    else
	echo "Using FreeBSD kernel from previous build"
    fi
}

# freebsd_installworld: Install FreeBSD world to image
#
# $1: Root directory of UFS partition
#
freebsd_installworld ( ) {
    cd $FREEBSD_SRC
    echo "Installing FreeBSD world onto the UFS partition at "`date`
    make TARGET_ARCH=$TARGET_ARCH DEBUG_FLAGS=-g DESTDIR=$1 installworld > ${BUILDOBJ}/_.installworld.log 2>&1
    make TARGET_ARCH=$TARGET_ARCH DESTDIR=$1 distrib-dirs > ${BUILDOBJ}/_.distrib-dirs.log 2>&1
    make TARGET_ARCH=$TARGET_ARCH DESTDIR=$1 distribution > ${BUILDOBJ}/_.distribution.log 2>&1
}

# freebsd_installkernel: Install FreeBSD kernel to image
#
# $1: Root directory of UFS partition
#
freebsd_installkernel ( ) {
    cd $FREEBSD_SRC
    echo "Installing FreeBSD kernel onto the UFS partition at "`date`
    make TARGET_ARCH=$TARGET_ARCH DESTDIR=$1 KERNCONF=${KERNCONF} installkernel > ${BUILDOBJ}/_.installkernel.log 2>&1
}

# freebsd_ubldr_build:  Build the ubldr loader program.
#
# $1: base address of compiled loader
#
freebsd_ubldr_build ( ) {
    if [ ! -f ${BUILDOBJ}/ubldr/ubldr ]; then
	echo "Building FreeBSD $TARGET_ARCH ubldr"
	rm -rf ${BUILDOBJ}/ubldr
	mkdir -p ${BUILDOBJ}/ubldr

	cd ${FREEBSD_SRC}
	ubldr_makefiles=`pwd`/share/mk
	buildenv=`make TARGET_ARCH=$TARGET_ARCH buildenvvars`
	cd sys/boot
	eval $buildenv make -m $ubldr_makefiles obj > ${BUILDOBJ}/_.ubldr.build.log
	eval $buildenv make -m $ubldr_makefiles depend >> ${BUILDOBJ}/_.ubldr.build.log
	eval $buildenv make UBLDR_LOADADDR=$1 -m $ubldr_makefiles all >> ${BUILDOBJ}/_.ubldr.build.log
	cd arm/uboot
	eval $buildenv make DESTDIR=${BUILDOBJ}/ubldr/ BINDIR= NO_MAN=true -m $ubldr_makefiles install >> ${BUILDOBJ}/_.ubldr.build.log
    else
	echo "Using FreeBSD ubldr from previous build"
    fi
}

# freebsd_ubldr_copy:  Copy the compiled ubldr files
# to the specified directory.
#
# $1: Target directory to receive ubldr files
#
freebsd_ubldr_copy ( ) {
    echo "Installing ubldr"
    cp ${BUILDOBJ}/ubldr/ubldr $1
    cp ${BUILDOBJ}/ubldr/loader.help $1
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
    portsnap fetch > ${BUILDOBJ}/_.portsnap.fetch.log
    echo "Installing ports tree at "`date`
    portsnap -p $1/usr/ports extract > ${BUILDOBJ}/_.portsnap.extract.log
}
