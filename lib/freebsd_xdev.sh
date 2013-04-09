FREEBSD_XDEV_PREFIX=


# freebsd_xdev_test: Verify that xdev tools exist.
#
# TODO: support armv6 here as well.
freebsd_xdev_test ( ) {
    case ${TARGET_ARCH} in
	arm*) TARGET=arm
	    ;;
	mips*) TARGET=mips
	    ;;
	pc98) TARGET=i386
	    ;;
	powerpc*) TARGET=powerpc
	    ;;
	*) TARGET=${TARGET_ARCH}
	    ;;
    esac
    FREEBSD_XDEV_PREFIX=${TARGET_ARCH}-freebsd-
    CC=${FREEBSD_XDEV_PREFIX}cc
    # We need the cross-tools for arm, if they're not already built.
    # This should work with arm.arm or arm.armv6 equally well.
    if [ -z `which ${CC}` ]; then
	echo "Can't find appropriate FreeBSD xdev tools."
	echo "If you have FreeBSD-CURRENT sources in /usr/src, you can build these with the following command:"
	echo
	echo "cd /usr/src && sudo make XDEV=${TARGET} XDEV_ARCH=${TARGET_ARCH} xdev"
	echo
	echo "Run this script again after you have the xdev tools installed."
	exit 1
    fi
    _INCLUDE_DIR=`${CC} -print-file-name=include`
    if [ ! -e "${_INCLUDE_DIR}/stdarg.h" ]; then
	echo "FreeBSD xdev tools are broken."
	echo "The following command should print the full path to the crossbuild"
	echo "include directory (containing stdarg.h, for example):"
	echo "  $ ${CC} -print-file-name=include"
	echo "Please install a newer version of the xdev tools."
	exit 1
    fi
    echo "Found FreeBSD xdev tools for ARM"
}
