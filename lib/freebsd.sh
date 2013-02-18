# This should be overridden by the board setup
TARGET_ARCH=armv6

# Board setup should not touch these, so users can
FREEBSD_SRC=/usr/src
FREEBSD_INSTALL_WORLD=y
FREEBSD_INSTALL_KERNEL=y
FREEBSD_WORLD_EXTRA_ARGS=""
FREEBSD_BUILDWORLD_EXTRA_ARGS=""
FREEBSD_INSTALLWORLD_EXTRA_ARGS=""
FREEBSD_KERNEL_EXTRA_ARGS=""
FREEBSD_BUILDKERNEL_EXTRA_ARGS=""
FREEBSD_INSTALLKERNEL_EXTRA_ARGS=""

# Hooks for board setup
FREEBSD_WORLD_BOARD_ARGS=""
FREEBSD_BUILDWORLD_BOARD_ARGS=""
FREEBSD_INSTALLWORLD_BOARD_ARGS=""
FREEBSD_KERNEL_BOARD_ARGS=""
FREEBSD_BUILDKERNEL_BOARD_ARGS=""
FREEBSD_INSTALLKERNEL_BOARD_ARGS=""

# Since we're building with special flags, keep
# the obj tree separate from /usr/obj.
MAKEOBJDIRPREFIX=${WORKDIR}/obj
export MAKEOBJDIRPREFIX

WORLDJOBS=4
KERNJOBS=4

freebsd_download_instructions ( ) {
    echo
    echo "You can obtain a suitable FreeBSD source tree with the folowing commands:"
    echo
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

# Common code for buildworld and buildkernel.
# In particular, this compares the command we're about to
# run to the previous run and rebuilds if anything is different.
#
_freebsd_build ( ) {
    if diff ${WORKDIR}/_.build$1.sh ${WORKDIR}/_.built-$1 >/dev/null 2>&1
    then
	echo "Using FreeBSD $1 from previous build"
	return 0
    fi

    echo "Building FreeBSD ${TARGET_ARCH} ${KERNCONF} $1 at "`date`" (Logging to ${WORKDIR}/_.build$1.log)"

    if [ -f ${WORKDIR}/_.built-$1 ]
    then
	echo " Rebuilding because previous build$1 used different flags:"
	echo " Old: "`cat ${WORKDIR}/_.built-$1`
	echo " new: "`cat ${WORKDIR}/_.build$1.sh`
	rm ${WORKDIR}/_.built-$1
    fi

    cd $FREEBSD_SRC
    if /bin/sh -e ${WORKDIR}/_.build$1.sh > ${WORKDIR}/_.build$1.log 2>&1
    then
	mv ${WORKDIR}/_.build$1.sh ${WORKDIR}/_.built-$1
    else
	echo "Failed to build FreeBSD $1."
	echo "Log in ${WORKDIR}/_.build$1.log"
	exit 1
    fi
}

# freebsd_buildworld: Build FreeBSD world.
#
# $@: additional make arguments
#
freebsd_buildworld ( ) {
    _FREEBSD_WORLD_ARGS="TARGET_ARCH=$TARGET_ARCH ${FREEBSD_WORLD_EXTRA_ARGS} ${FREEBSD_WORLD_BOARD_ARGS}"
    echo make ${_FREEBSD_WORLD_ARGS} ${FREEBSD_BUILDWORLD_EXTRA_ARGS} ${FREEBSD_BUILDWORLD_BOARD_ARGS} "$@" -j ${WORLDJOBS} buildworld > ${WORKDIR}/_.buildworld.sh
    _freebsd_build world
}


# freebsd_buildkernel: Build FreeBSD kernel if it's not already built.
#
# $@: arguments to make.
#
freebsd_buildkernel ( ) {
    _FREEBSD_KERNEL_ARGS="TARGET_ARCH=${TARGET_ARCH} KERNCONF=${KERNCONF} ${FREEBSD_KERNEL_EXTRA_ARGS} ${FREEBSD_KERNEL_BOARD_ARGS}"
    echo make  ${_FREEBSD_KERNEL_ARGS} ${FREEBSD_BUILDKERNEL_EXTRA_ARGS} ${FREEBSD_KERNEL_BOARD_ARGS} "$@" -j $KERNJOBS buildkernel > ${WORKDIR}/_.buildkernel.sh
    _freebsd_build kernel
}

# freebsd_installworld: Install FreeBSD world to image
#
# $1: Root directory of UFS partition
#
freebsd_installworld ( ) {
    cd $FREEBSD_SRC
    echo "Installing FreeBSD world onto the UFS partition at "`date`
    if make ${_FREEBSD_WORLD_ARGS} ${FREEBSD_INSTALLWORLD_EXTRA_ARGS} ${FREEBSD_INSTALLWORLD_BOARD_ARGS} DESTDIR=$1 installworld > ${WORKDIR}/_.installworld.log 2>&1
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
    echo "Installing FreeBSD kernel to $1 at "`date`
    echo make ${_FREEBSD_KERNEL_ARGS} ${FREEBSD_INSTALLKERNEL_EXTRA_ARGS} ${FREEBSD_INSTALLKERNEL_BOARD_ARGS} DESTDIR=$1 installkernel > ${WORKDIR}/_.installkernel.sh
    if /bin/sh -e ${WORKDIR}/_.installkernel.sh > ${WORKDIR}/_.installkernel.log 2>&1
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
    eval $buildenv make "$@" -m $ubldr_makefiles all >> ${WORKDIR}/_.ubldr.build.log || exit 1
    cd arm/uboot
    eval $buildenv make DESTDIR=${WORKDIR}/ubldr/ BINDIR= NO_MAN=true -m $ubldr_makefiles install >> ${WORKDIR}/_.ubldr.build.log || exit 1
}

# freebsd_ubldr_copy:  Copy the compiled ubldr files
# to the specified directory.
#
# $1: Target directory to receive ubldr files
#
freebsd_ubldr_copy ( ) {
    freebsd_ubldr_copy_ubldr
    freebsd_ubldr_copy_ubldr_help
}

freebsd_ubldr_copy_ubldr ( ) {
    echo "Installing ubldr"
    cp ${WORKDIR}/ubldr/ubldr $1 || exit 1
}

freebsd_ubldr_copy_ubldr_help ( ) {
    echo "Installing ubldr help file"
    cp ${WORKDIR}/ubldr/loader.help $1 || exit 1
}

# freebsd_install_usr_src:  Copy FREEBSD_SRC tree
# to /usr/src in image.
#
# $1: root of image
#
_freebsd_install_usr_src ( ) {
    echo "Copying source to /usr/src on disk image at "`date`
    mkdir -p $1/usr/src
    # Note: Includes the .svn directory.
    (cd $FREEBSD_SRC ; tar cf - .) | (cd $1/usr/src; tar xpf -)
}

freebsd_install_usr_src ( ) {
    _freebsd_install_usr_src ${UFS_MOUNT}
}

# freebsd_install_usr_ports:  Download and install
# a /usr/ports tree to the image.
#
# $1:  root of image
#
_freebsd_install_usr_ports ( ) {
    mkdir -p $1/usr/ports
    echo "Updating ports snapshot at "`date`
    portsnap fetch > ${WORKDIR}/_.portsnap.fetch.log
    echo "Installing ports tree at "`date`
    portsnap -p $1/usr/ports extract > ${WORKDIR}/_.portsnap.extract.log
}

freebsd_install_usr_ports ( ) {
    _freebsd_install_usr_ports ${UFS_MOUNT}
}


# $1: name of dts or dtb file
# $2: destination dts or dtb file or dir
#
# If $1 and $2 have different extensions (".dts" vs. ".dtb"),
# the dtc compiler will be used to translate formats.  If
# $2 is a directory or the extensions are the same, this
# devolves into a 'cp'.
#
freebsd_install_fdt ( ) (
    cd $FREEBSD_SRC/sys/boot/fdt/dts
    case $1 in
	*.dtb)
	    case $2 in
		*.dtb)
		    cp $1 $2
		    ;;
		*.dts)
		    dtc -I dtb -O dts -p 8192 -o $2 $1
		    ;;
		*)
		    if [ -d $2 ]; then
			cp $1 $2
		    else
			echo "Can't compile $1 to $2"
			exit 1
		    fi
		    ;;
	    esac
	    ;;
	*.dts)
	    case $2 in
		*.dts)
		    cp $1 $2
		    ;;
		*.dtb)
		    dtc -I dts -O dtb -p 8192 -o $2 $1
		    ;;
		*)
		    if [ -d $2 ]; then
			cp $1 $2
		    else
			echo "Can't compile $1 to $2"
			exit 1
		    fi
		    ;;
	    esac
	    ;;
    esac
)
