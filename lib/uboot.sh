# Board setup will often overwrite this.

. ${LIBDIR}/freebsd_xdev.sh

# $1: Variable that holds root of U-Boot tree
# $2...: list of commands to fetch appropriate U-Boot sources
_uboot_download_instructions ( ) (
    _UBOOT_SRC_VAR=$1
    _UBOOT_SRC=`eval echo \\$$1`
    shift
    echo
    echo "Expected to see U-Boot sources in"
    echo "    $_UBOOT_SRC"
    echo "Use the following command to get the U-Boot sources"
    echo
    for l in "$@"; do
        echo " $ $l"
    done
    echo
    echo "Edit \$$_UBOOT_SRC_VAR in config.sh if you want the sources in a different directory."
    echo "Run this script again after you have the U-Boot sources installed."
)

#
# $1: Variable that holds root of U-Boot tree
# $2: path to a file that should be in this U-Boot tree
# $3...: list of commands to fetch appropriate U-Boot sources
#
uboot_test ( ) {
    # We use FreeBSD xdev tools to build U-Boot
    freebsd_xdev_test

    if [ -z `which gmake` ]; then
        echo "U-Boot build requires 'gmake'"
        echo "Please install devel/gmake and re-run this script."
        exit 1
    fi
    if [ -z `which gsed` ]; then
        echo "U-Boot build requires 'gsed'"
        echo "Please install textproc/gsed and re-run this script."
        exit 1
    fi
    if [ -f "$2" ]; then
        _UBOOT_SRC=`eval echo \\$$1`
        echo "Found U-Boot sources in:"
        echo "    $_UBOOT_SRC"
    else
        _UBOOT_SRC_VAR=$1
        shift
        shift
        _uboot_download_instructions $_UBOOT_SRC_VAR "$@"
        exit 1
    fi

}

# uboot_patch: Apply patches to the U-Boot sources.
#
# $1: Base directory of U-Boot sources
# $2 ... : List of patch files to apply
uboot_patch ( ) (
    _UBOOT_SRC=$1
    shift
    echo "$@" > ${_UBOOT_SRC}/_.uboot.to.be.patched
    if [ -f "${_UBOOT_SRC}/_.uboot.patched" ]; then
        # Some patches were applied
        if diff ${_UBOOT_SRC}/_.uboot.patched ${_UBOOT_SRC}/_.uboot.to.be.patched >/dev/null; then
            # They're the same, so the expected patches were applied.
            rm ${_UBOOT_SRC}/_.uboot.to.be.patched
            return 0
        else
            echo "U-Boot sources have already been patched, but with the wrong patches."
            echo "Please check out fresh U-Boot sources and try again."
            exit 1
        fi
    fi

    if [ -f ${_UBOOT_SRC}/_.uboot.patched ]; then
        touch ${_UBOOT_SRC}/_.uboot.patched
        return 0
    fi

    cd "$_UBOOT_SRC"
    echo "Patching U-Boot at "`date`
    echo "    (Logging to ${_UBOOT_SRC}/_.uboot.patch.log)"
    # This function is usually called with an argument like
    # 'patches/*.patch'; if there are no patch files, then $@ will have
    # "patches/*.patch" and we want to just skip the rest.
    if ls "$@" 2>/dev/null; then
        for p in "$@"; do
            echo "   Applying patch $p"
            if patch -N -p1 < $p >> ${_UBOOT_SRC}/_.uboot.patch.log 2>&1; then
                # success
            else
                echo "Patch didn't apply: $p"
                echo "  Log in ${_UBOOT_SRC}/_.uboot.patch.log"
                exit 1
            fi
        done
    else
        echo "   No patches found; skipping"
    fi
    mv ${_UBOOT_SRC}/_.uboot.to.be.patched ${_UBOOT_SRC}/_.uboot.patched
    echo "$@" > ${_UBOOT_SRC}/_.uboot.patched
    rm -f ${_UBOOT_SRC}/_.uboot.configured
)

# uboot_configure
#
# $1: Base directory of U-Boot sources
# $2: Name of U-Boot configuration to use.
uboot_configure ( ) {
    echo "$2" > $1/_.uboot.to.be.configured
    if [ -f $1/_.uboot.configured ]; then
        return 0
    fi

    cd "$1"
    echo "Configuring U-Boot at "`date`
    echo "    (Logging to $1/_.uboot.configure.log)"
    if gmake CROSS_COMPILE=${FREEBSD_XDEV_PREFIX} $2 > $1/_.uboot.configure.log 2>&1; then
        # success
    else
        echo "  Failed to configure U-Boot."
        echo "  Log in $1/_.uboot.configure.log"
        exit 1
    fi
    echo "$2" > $1/_.uboot.configured
    rm -f $1/_.uboot.built
}

# uboot_build
#
# $1: base dir of U-Boot sources
uboot_build ( ) (
    if [ -f $1/_.uboot.built ]; then
        echo "Using U-Boot from previous build."
        return 0
    fi

    cd "$1"
    echo "Building U-Boot at "`date`
    echo "    (Logging to $1/_.uboot.build.log)"
    if gmake SED=gsed HOSTCC=cc CROSS_COMPILE=${FREEBSD_XDEV_PREFIX} > $1/_.uboot.build.log 2>&1; then
        # success
    else
        echo "  Failed to build U-Boot."
        echo "  Log in $1/_.uboot.build.log"
        exit 1
    fi

    touch $1/_.uboot.built
)

#
#  $1 name of script file
#  $2 output file
# 
uboot_mkimage ( ) (
    echo "Building and Installing U-Boot script"
    
    # location of input file
    MKIMAGE_INPUT="$BOARDDIR/$1";
 
    # location of output file.  This will end up being the FAT filesystem
    MKIMAGE_OUTPUT="$2" 

    # location of mkimage
    MKIMAGE="$WANDBOARD_UBOOT_SRC/tools/mkimage"

    # execute mkimage
    eval "$MKIMAGE -A arm -O FreeBSD -T script -C none -d $MKIMAGE_INPUT $MKIMAGE_OUTPUT" > ${WORKDIR}/_.mkimage.log
)

