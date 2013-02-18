# Board setup will often overwrite this.
UBOOT_SRC=$TOPDIR/u-boot

. ${LIBDIR}/freebsd_xdev.sh

_uboot_download_instructions ( ) {
    echo
    echo "Expected to see U-Boot sources in $UBOOT_SRC"
    echo "Use the following command to get the U-Boot sources"
    echo
    for l in "$@"; do
	echo " $ $l"
    done
    echo
    echo "Edit \$UBOOT_SRC in config.sh if you want the sources in a different directory."
    echo "Run this script again after you have the U-Boot sources installed."
}

#
# $1: path to a file that should be in this U-Boot tree
# $2...: list of commands to fetch appropriate U-Boot sources
#
uboot_test ( ) {
    # We use FreeBSD xdev tools to build U-Boot
    freebsd_xdev_test

    if [ ! -f "$1" ]; then
	shift
	_uboot_download_instructions "$@"
	exit 1
    fi
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

    echo "Found U-Boot sources in $UBOOT_SRC"
}

# uboot_patch: Apply patches to the U-Boot sources.
#
# $@: List of patch files to apply
uboot_patch ( ) {
    echo "$@" > ${UBOOT_SRC}/_.uboot.to.be.patched
    if [ -f "${UBOOT_SRC}/_.uboot.patched" ]; then
	# Some patches were applied
	if diff ${UBOOT_SRC}/_.uboot.patched ${UBOOT_SRC}/_.uboot.to.be.patched >/dev/null; then
	    # They're the same, so the expected patches were applied.
	    rm ${UBOOT_SRC}/_.uboot.to.be.patched
	    return 0
	else
	    echo "U-Boot sources have already been patched, but with the wrong patches."
	    echo "Please check out fresh U-Boot sources and try again."
	    exit 1
	fi
    fi

    if [ -f ${WORKDIR}/_.uboot.patched ]; then
	touch ${UBOOT_SRC}/_.uboot.patched
	return 0
    fi

    cd "$UBOOT_SRC"
    echo "Patching U-Boot. (Logging to ${WORKDIR}/_.uboot.patch.log)"
    # This function is usually called with an argument like
    # 'patches/*.patch'; if there are no patch files, then $@ will have 
    # "patches/*.patch" and we want to just skip the rest.
    if ls "$@" 2>/dev/null; then
	for p in "$@"; do
	    echo "   Applying patch $p"
	    if patch -N -p1 < $p >> ${WORKDIR}/_.uboot.patch.log 2>&1; then
		# success
	    else
		echo "Patch didn't apply: $p"
		echo "  Log in ${WORKDIR}/_.uboot.patch.log"
		exit 1
	    fi
	done
    else
	echo "   No patches found; skipping"
    fi
    mv ${UBOOT_SRC}/_.uboot.to.be.patched ${UBOOT_SRC}/_.uboot.patched
    echo "$@" > ${UBOOT_SRC}/_.uboot.patched
    rm -f ${UBOOT_SRC}/_.uboot.configured
}

# uboot_configure
#
# $1: Name of U-Boot configuration to use.
uboot_configure ( ) {
    echo "$1" > ${UBOOT_SRC}/_.uboot.to.be.configured
    if [ -f ${UBOOT_SRC}/_.uboot.configured ]; then
	return 0
    fi

    cd "$UBOOT_SRC"
    echo "Configuring U-Boot at "`date`
    echo "    (Logging to ${WORKDIR}/_.uboot.configure.log)"
    if gmake CROSS_COMPILE=arm-freebsd- $1 > ${WORKDIR}/_.uboot.configure.log 2>&1; then
	# success
    else
	echo "  Failed to configure U-Boot."
	echo "  Log in ${WORKDIR}/_.uboot.configure.log"
	exit 1
    fi
    echo "$1" > ${UBOOT_SRC}/_.uboot.configured
    rm -f ${UBOOT_SRC}/_.uboot.built
}

# uboot_build
#
uboot_build ( ) {
    if [ -f ${UBOOT_SRC}/_.uboot.built ]; then
	echo "Using U-Boot from previous build."
	return 0
    fi

    cd "$UBOOT_SRC"
    echo "Building U-Boot at "`date`
    echo "    (Logging to ${WORKDIR}/_.uboot.build.log)"
    if gmake SED=gsed CROSS_COMPILE=arm-freebsd- > ${WORKDIR}/_.uboot.build.log 2>&1; then
	# success
    else
	echo "  Failed to build U-Boot."
	echo "  Log in ${WORKDIR}/_.uboot.build.log"
	exit 1
    fi

    touch ${UBOOT_SRC}/_.uboot.built
}
