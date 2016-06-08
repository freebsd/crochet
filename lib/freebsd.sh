# This should be overridden by the board setup
TARGET_ARCH='needs-to-be-set-by-board-definition'

# Board setup should not touch these, so users can
FREEBSD_SRC=/usr/src
FREEBSD_EXTRA_ARGS=""
FREEBSD_WORLD_EXTRA_ARGS=""
FREEBSD_BUILDWORLD_EXTRA_ARGS=""
FREEBSD_INSTALLWORLD_EXTRA_ARGS=""
FREEBSD_KERNEL_EXTRA_ARGS=""
FREEBSD_BUILDKERNEL_EXTRA_ARGS=""
FREEBSD_INSTALLKERNEL_EXTRA_ARGS=""

# Make non-empty to override the usual build-avoidance
FREEBSD_FORCE_BUILDKERNEL=""
FREEBSD_FORCE_BUILDWORLD=""

# Hooks for board setup
FREEBSD_WORLD_BOARD_ARGS=""
FREEBSD_BUILDWORLD_BOARD_ARGS=""
FREEBSD_INSTALLWORLD_BOARD_ARGS=""
FREEBSD_KERNEL_BOARD_ARGS=""
FREEBSD_BUILDKERNEL_BOARD_ARGS=""
FREEBSD_INSTALLKERNEL_BOARD_ARGS=""

# Since we're building with special flags, keep
# the obj tree separate from /usr/obj.
SRCCONF=/dev/null
__MAKE_CONF=/dev/null

if [ -z ${WORLDJOBS} ]; then
	WORLDJOBS="-j $(sysctl -n hw.ncpu)"
else
	WORLDJOBS="-j${WORLDJOBS}"
fi
if [ -z ${KERNJOBS} ]; then
	KERNJOBS="-j $(sysctl -n hw.ncpu)"
else
	KERNJOBS="-j${KERNJOBS}"
fi

freebsd_default_makeobjdirprefix ( ) {
    if [ -z "$MAKEOBJDIRPREFIX" ]; then
        MAKEOBJDIRPREFIX=${WORKDIR}/obj
    fi
    export MAKEOBJDIRPREFIX
}
strategy_add $PHASE_POST_CONFIG freebsd_default_makeobjdirprefix

freebsd_download_instructions ( ) {
    echo
    echo "You can obtain a suitable FreeBSD source tree with the folowing commands:"
    echo
    for l in "$@"; do
        echo "$l"
    done
    echo
    echo "Set \$FREEBSD_SRC in ${CONFIGFILE:-the -c <config file>} if you have the sources in a different directory."
    echo "Run this script again after you have the sources installed."
    exit 1
}

freebsd_dtc_test ( ) {
    if dtc -v >/dev/null
    then
        true
    else
        echo "You need the dtc compiler installed on your system."
        echo "Newer versions of FreeBSD have this installed by default."
        echo "On older FreeBSD versions:"
        echo "  $ cd /usr/src/usr.bin/dtc"
        echo "  $ make"
        echo "  $ make install"
        echo ""
        echo "Rerun this script after you install it."
        exit 1
    fi
}

freebsd_src_version ( ) {
    FREEBSD_VERSION=`/usr/bin/grep "REVISION=" ${FREEBSD_SRC}/sys/conf/newvers.sh | awk 'BEGIN {FS="="} {print $2}' | /usr/bin/tr -d '"'`
    FREEBSD_MAJOR_VERSION=`echo $FREEBSD_VERSION | awk 'BEGIN {FS="."} {print $1}'`
    echo "Building FreeBSD version: $FREEBSD_VERSION";
}

# find the OBJS
freebsd_objdir ( ) {
    # This is still broken. It gets the OBJDIR wrong when
    # doing native builds.
    # TODO: Fix it or remove the need for it.  (We
    # really should not need this; we can instead use the following
    # idiom to copy files out of the obj tree without actually
    # knowing where it is:
    #     "cd src-dir-location; make DESTDIR=XYZ install" 
    
    if [ "$FREEBSD_MAJOR_VERSION" -eq "8" ]
    then
        FREEBSD_OBJDIR=${MAKEOBJDIRPREFIX}/$TARGET_ARCH${FREEBSD_SRC}
    fi
    if [ "$FREEBSD_MAJOR_VERSION" -ge "9" ]
    then
        buildenv=`make -C $FREEBSD_SRC TARGET_ARCH=$TARGET_ARCH buildenvvars`
        FREEBSD_OBJDIR=`eval $buildenv printenv MAKEOBJDIRPREFIX`${FREEBSD_SRC}
    fi
    echo "Object files are at: "${FREEBSD_OBJDIR}
}

# freebsd_src_test: Check that this looks like a FreeBSD src tree.
#
# $1: Name of kernel configuration we expect
#
freebsd_src_test ( ) {
    # FreeBSD source tree has certain files:
    for f in COPYRIGHT Makefile Makefile.inc1 UPDATING; do
        if [ \! -f "$FREEBSD_SRC/$f" ]; then
            echo "This does not look like a FreeBSD source tree."
            echo "Did not find: $FREEBSD_SRC/$f"
            shift; freebsd_download_instructions "$@"
            exit 1
        fi
    done
    # FreeBSD source tree has certain directories:
    for d in bin usr.bin usr.sbin contrib gnu cddl sys sys/arm sys/i386; do
        if [ \! -d "$FREEBSD_SRC/$d" ]; then
            echo "This does not look like a FreeBSD source tree."
            echo "Did not find: $FREEBSD_SRC/$d"
            shift; freebsd_download_instructions "$@"
            exit 1
        fi
    done
    # Make sure it has the config file we expect under the appropriate arch:
    case ${TARGET_ARCH} in
        aarch64) ARCH=arm64
            ;;
        arm*) ARCH=arm
            ;;
        mips*) ARCH=mips
            ;;
        pc98) ARCH=i386
            ;;
        powerpc*) ARCH=powerpc
            ;;
        *) ARCH=${TARGET_ARCH}
            ;;
    esac
    if [ \! -f "$FREEBSD_SRC/sys/$ARCH/conf/$1" ]; then
        echo "Didn't find $FREEBSD_SRC/sys/$ARCH/conf/$1"
        shift; freebsd_download_instructions "$@"
        exit 1
    fi
    freebsd_src_version
    freebsd_objdir
    echo "Found suitable FreeBSD source tree in:"
    echo "    $FREEBSD_SRC"
}

# freebsd_current_test:  Check that FreeBSD-CURRENT sources are available
# (Specialized version of freebsd_src_test for the common case.)
# TODO: Add more checks here to verify that the src tree really
# is -CURRENT.
freebsd_current_test ( ) {
    freebsd_src_test \
        ${KERNCONF} \
        " $ svn co https://svn0.us-west.freebsd.org/base/head $FREEBSD_SRC"
}

# Common code for buildworld and buildkernel.  In particular, this
# compares the command we're about to run to the previous run and
# rebuilds if anything is different.  So if you build multiple
# images for multiple systems with the same options, you won't
# have to repeat a full buildworld and/or buildkernel.
#
# TODO: We could do even better by using a separate MKOBJDIRPREFIX
# for each different combination of buildworld flags.  Then
# each separate world would end up in a separate directory.
#
_freebsd_build ( ) {
    LOGFILE=${WORKDIR}/_.build$1.$2.log
    if diff ${WORKDIR}/_.build$1.$2.sh ${WORKDIR}/_.built-$1.$2 >/dev/null 2>&1
    then
        echo "Using FreeBSD $2 $1 from previous build"
        return 0
    fi

    echo "Building FreeBSD $2 $1 at "`date`
    echo "    (Logging to ${LOGFILE})"

    if [ -f ${WORKDIR}/_.built-$1.$2 ]
    then
        echo " Rebuilding because previous build used different flags:"
        echo " Old: "`cat ${WORKDIR}/_.built-$1.$2`
        echo " new: "`cat ${WORKDIR}/_.build$1.$2.sh`
        rm -f ${WORKDIR}/_.built-$1.$2
    fi

    cd $FREEBSD_SRC
    if /bin/sh -e ${WORKDIR}/_.build$1.$2.sh > ${LOGFILE} 2>&1
    then
        mv ${WORKDIR}/_.build$1.$2.sh ${WORKDIR}/_.built-$1.$2
    else
        echo "Failed to build FreeBSD $2 $1."
        echo "Log in ${LOGFILE}"
        echo
        tail ${LOGFILE}
        exit 1
    fi
}

# freebsd_buildworld: Build FreeBSD world.
#
# $@: additional make arguments
#
freebsd_buildworld ( ) {
    _FREEBSD_WORLD_ARGS="TARGET_ARCH=${TARGET_ARCH} SRCCONF=${SRCCONF} __MAKE_CONF=${__MAKE_CONF} ${FREEBSD_EXTRA_ARGS} ${FREEBSD_WORLD_EXTRA_ARGS} ${FREEBSD_WORLD_BOARD_ARGS}"
    if [ -n "${TARGET_CPUTYPE}" ]; then
        _FREEBSD_WORLD_ARGS="TARGET_CPUTYPE=${TARGET_CPUTYPE} ${_FREEBSD_WORLD_ARGS}"
    fi
    CONF=${TARGET_ARCH}
    echo make ${_FREEBSD_WORLD_ARGS} ${FREEBSD_BUILDWORLD_EXTRA_ARGS} ${FREEBSD_BUILDWORLD_BOARD_ARGS} "$@" ${WORLDJOBS} buildworld > ${WORKDIR}/_.buildworld.${CONF}.sh
    if [ -n "${FREEBSD_FORCE_BUILDWORLD}" ]; then
        rm -f ${WORKDIR}/_.built-world.${CONF}
    fi
    _freebsd_build world ${CONF}
}


# freebsd_buildkernel: Build FreeBSD kernel if it's not already built.
#
# $@: arguments to make.
#
freebsd_buildkernel ( ) {
    _FREEBSD_KERNEL_ARGS="TARGET_ARCH=${TARGET_ARCH} SRCCONF=${SRCCONF} __MAKE_CONF=${__MAKE_CONF} KERNCONF=${KERNCONF} ${FREEBSD_EXTRA_ARGS} ${FREEBSD_KERNEL_EXTRA_ARGS} ${FREEBSD_KERNEL_BOARD_ARGS}"
    if [ -n "${TARGET_CPUTYPE}" ]; then
        _FREEBSD_KERNEL_ARGS="TARGET_CPUTYPE=${TARGET_CPUTYPE} ${_FREEBSD_KERNEL_ARGS}"
    fi
    CONF=${TARGET_ARCH}-${KERNCONF}
    echo make  ${_FREEBSD_KERNEL_ARGS} ${FREEBSD_BUILDKERNEL_EXTRA_ARGS} ${FREEBSD_KERNEL_BOARD_ARGS} "$@" $KERNJOBS buildkernel > ${WORKDIR}/_.buildkernel.${CONF}.sh
    if [ -n "${FREEBSD_FORCE_BUILDKERNEL}" ]; then
        rm -f ${WORKDIR}/_.built-kernel.${CONF}
    fi
    _freebsd_build kernel ${CONF}
}


# freebsd_installworld: Install FreeBSD world to image
#
# $1: Root directory of UFS partition
#
freebsd_installworld ( ) {
    cd $FREEBSD_SRC
    CONF=${TARGET_ARCH}
    echo "Installing FreeBSD world at "`date`
    echo "    Destination: $1"
    if make SRCCONF=${SRCCONF} __MAKE_CONF=${__MAKE_CONF} ${_FREEBSD_WORLD_ARGS} ${FREEBSD_INSTALLWORLD_EXTRA_ARGS} ${FREEBSD_INSTALLWORLD_BOARD_ARGS} DESTDIR=$1 installworld > ${WORKDIR}/_.installworld.${CONF}.log 2>&1
    then
        true # success
    else
        echo "Installworld failed."
        echo "    Log: ${WORKDIR}/_.installworld.${CONF}.log"
        exit 1
    fi

    if make SRCCONF=${SRCCONF} __MAKE_CONF=${__MAKE_CONF} TARGET_ARCH=$TARGET_ARCH DESTDIR=$1 distrib-dirs > ${WORKDIR}/_.distrib-dirs.${CONF}.log 2>&1
    then
        true # success
    else
        echo "distrib-dirs failed"
        echo "    Log: ${WORKDIR}/_.distrib-dirs.${CONF}.log"
        exit 1
    fi

    if make SRCCONF=${SRCCONF} __MAKE_CONF=${__MAKE_CONF} TARGET_ARCH=$TARGET_ARCH DESTDIR=$1 distribution > ${WORKDIR}/_.distribution.${CONF}.log 2>&1
    then
        true # success
    else
        echo "distribution failed"
        echo "    Log: ${WORKDIR}/_.distribution.${CONF}.log"
        exit 1
    fi

    # Touch up /etc/src.conf so that native "make buildkernel" will DTRT:
    echo "KERNCONF=${KERNCONF}" >> $1/etc/src.conf

    # Add /firstboot marker so /etc/rc will DTRT
    touch $1/firstboot
}

# freebsd_installkernel: Install FreeBSD kernel to image
#
# $1: Root directory of FreeBSD system where we should install
# kernel; defaults to cwd.
#
freebsd_installkernel ( ) {
    if [ -n "$1" ]; then
        cd $1
    fi
    DESTDIR=`pwd`
    CONF=${TARGET_ARCH}-${KERNCONF}
    cd $FREEBSD_SRC
    echo "Installing FreeBSD kernel at "`date`
    echo "    Destination: $DESTDIR"
    echo make ${_FREEBSD_KERNEL_ARGS} ${FREEBSD_INSTALLKERNEL_EXTRA_ARGS} ${FREEBSD_INSTALLKERNEL_BOARD_ARGS} DESTDIR=$DESTDIR installkernel > ${WORKDIR}/_.installkernel.${CONF}.sh
    if /bin/sh -e ${WORKDIR}/_.installkernel.${CONF}.sh > ${WORKDIR}/_.installkernel.${CONF}.log 2>&1
    then
        true # success
    else
        echo "installkernel failed"
        echo "    Log: ${WORKDIR}/_.installkernel.${CONF}.log"
        exit 1
    fi
}

# freebsd_ubldr_build:  Build the ubldr loader program.
# Note: Assumes world is already built.  Since ubldr
# varies slightly between systems, we identify the ubldr
# by both TARGET_ARCH and KERNCONF so that ubldr builds
# for different systems won't get confused.
#
# $@: make arguments for building
#
freebsd_ubldr_build ( ) {
    cd ${FREEBSD_SRC}
    CONF=${TARGET_ARCH}-${KERNCONF}
    UBLDR_DIR=${WORKDIR}/ubldr-${CONF}
    LOGFILE=${UBLDR_DIR}/_.ubldr.${CONF}.build.log
    ubldr_makefiles=`pwd`/share/mk
    buildenv=`make TARGET_ARCH=$TARGET_ARCH buildenvvars`
    buildenv="$buildenv SRCCONF=${SRCCONF} __MAKE_CONF=${__MAKE_CONF}"

    mkdir -p ${UBLDR_DIR}

    # Record the build command we plan to use.
    echo $buildenv make "$@" -m $ubldr_makefiles all > ${UBLDR_DIR}/_.ubldr.${CONF}.sh

    # If the command is unchanged, we won't rebuild.
    if diff ${UBLDR_DIR}/_.ubldr.${CONF}.built ${UBLDR_DIR}/_.ubldr.${CONF}.sh > /dev/null 2>&1
    then
        echo "Using ubldr from previous build"
        return 0
    fi

    echo "Building FreeBSD $CONF ubldr at "`date`
    echo "    (Logging to ${LOGFILE})"
    rm -rf ${UBLDR_DIR}/boot
    mkdir -p ${UBLDR_DIR}/boot/defaults

    cd sys/boot
    eval $buildenv make "$@" -m $ubldr_makefiles obj > ${LOGFILE} 2>&1
    eval $buildenv make "$@" -m $ubldr_makefiles clean >> ${LOGFILE} 2>&1
    eval $buildenv make "$@" -m $ubldr_makefiles depend >> ${LOGFILE} 2>&1
    if /bin/sh -e ${UBLDR_DIR}/_.ubldr.${CONF}.sh >> ${LOGFILE} 2>&1
    then
        mv ${UBLDR_DIR}/_.ubldr.${CONF}.sh ${UBLDR_DIR}/_.ubldr.${CONF}.built
        cd arm/uboot
        eval $buildenv make "$@" DESTDIR=${UBLDR_DIR}/ BINDIR=boot NO_MAN=true -m $ubldr_makefiles install >> ${LOGFILE} || exit 1
    else
        echo "Failed to build FreeBSD ubldr"
        echo "  Log in ${LOGFILE}"
        echo
        tail ${LOGFILE}
        exit 1
    fi
}

# freebsd_ubldr_copy:  Copy the compiled ubldr files
# to the specified directory.
#
# $1: Target directory to receive ubldr files
#
freebsd_ubldr_copy ( ) {
    echo "Installing all ubldr files in $1"
    CONF=${TARGET_ARCH}-${KERNCONF}
    (cd ${WORKDIR}/ubldr-${CONF}/boot && find . | cpio -pdum $1) || exit 1
}

freebsd_ubldr_copy_ubldr ( ) {
    if [ $1 = "." ]; then
	echo "Installing ubldr in ${PWD}"
    else
	echo "Installing ubldr in $1"
    fi
    CONF=${TARGET_ARCH}-${KERNCONF}
    cp ${WORKDIR}/ubldr-${CONF}/boot/ubldr* $1 || exit 1
}

freebsd_ubldr_copy_ubldr_help ( ) {
    echo "Installing ubldr help file in $1"
    CONF=${TARGET_ARCH}-${KERNCONF}
    cp ${WORKDIR}/ubldr-${CONF}/boot/loader.help $1 || exit 1
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
    _freebsd_install_usr_src ${BOARD_FREEBSD_MOUNTPOINT}
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
    _freebsd_install_usr_ports $1
}


_freebsd_get_machine ( ) {
    echo ${MACHINE}
}

# $1: name of dts or dtb file, relative to sys/boot/fdt/dts
# $2: destination dts or dtb file or dir, relative to cwd
#
# If $1 and $2 have different extensions (".dts" vs. ".dtb"),
# the dtc compiler will be used to translate formats.  If
# $2 is a directory or the extensions are the same, we still
# run it through dtc so that dtsi includes get expanded.
#
freebsd_install_fdt ( ) (
    buildenv=`cd $FREEBSD_SRC; make TARGET_ARCH=$TARGET_ARCH buildenvvars`
    buildenv_machine=`eval $buildenv _freebsd_get_machine`;
    _FDTDIR=$FREEBSD_SRC/sys/boot/fdt/dts
    if [ -f ${_FDTDIR}/${buildenv_machine}/${1} ]; then
        _FDTDIR=${_FDTDIR}/${buildenv_machine}
    fi
    mkdir -p ${WORKDIR}/fdt
    _DTBINTERMEDIATEDIR=`mktemp -d ${WORKDIR}/fdt/fdt.XXXXXX`
    case $1 in
        *.dts)
	    _DTSIN=${_FDTDIR}/$1
	    case ${FREEBSD_VERSION} in
		10.0|10.1) _DTBINTERMEDIATE=${_DTBINTERMEDIATEDIR}/out.dtb
		    ;;
		1*.*) _DTBINTERMEDIATE=${_DTBINTERMEDIATEDIR}
		    ;;
		*)
		    echo "ERROR: Crochet can only build images for FreeBSD 10.0 or later"
		    exit 1
		    ;;
	    esac
	    echo ${FREEBSD_SRC}/sys/tools/fdt/make_dtb.sh ${FREEBSD_SRC}/sys ${_DTSIN} ${_DTBINTERMEDIATE} | (cd ${FREEBSD_SRC}; make TARGET_ARCH=$TARGET_ARCH buildenv > /dev/null)
            case $2 in
                *.dts)
		    _DTSOUT=$2
		    dtc -I dtb -O dts ${_DTBINTERMEDIATEDIR}/*.dtb > ${_DTSOUT}
                    ;;
                *.dtb)
		    _DTBOUT=$2
		    cp ${_DTBINTERMEDIATEDIR}/*.dtb ${_DTBOUT}
                    ;;
                *)
                    echo "Can't compile $1 to $2"
                    exit 1
                    ;;
            esac
            ;;
	*)
	    echo "Cannot compile $1 to $2"
	    exit 1
	    ;;
    esac
)


#
# Replicate a FreeBSD install at $1 to $2
#
#
freebsd_replicate ( ) {
    echo "Replicating FreeBSD installation at ${1}"
    echo "                                 to ${2} at "`date`
    cd $1
    # -k (don't overwrite existing files) is specified because
    # otherwise pax will try to replace the journal (.sujournal) in
    # the destination UFS filesystem
    pax -r -w -p e -k . $2
    echo "Replication complete at "`date`
}


