FREEBSD_XDEV_PREFIX=

# freebsd_xdev_test: Verify that xdev tools exist.
#
freebsd_xdev_test ( ) {
    XDEV_ARCH=${TARGET_ARCH}
    case ${XDEV_ARCH} in
        arm*) XDEV=arm
            ;;
        mips*) XDEV=mips
            ;;
        pc98) XDEV=i386
            ;;
        powerpc*) XDEV=powerpc
            ;;
        *) XDEV=${XDEV_ARCH}
            ;;
    esac

    FREEBSD_XDEV_PREFIX=${XDEV_ARCH}-freebsd-
    CC=${FREEBSD_XDEV_PREFIX}cc
    if [ -z `which ${CC}` ]; then
        echo "Can't find appropriate FreeBSD xdev tools."
        echo "If you have FreeBSD-CURRENT sources in /usr/src, you can build these with the following command:"
        echo
        echo "cd /usr/src && sudo make XDEV=${XDEV} XDEV_ARCH=${XDEV_ARCH} xdev"
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
    echo "Found FreeBSD xdev tools for ${XDEV_ARCH}"
}
