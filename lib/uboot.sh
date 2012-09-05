
. ${LIBDIR}/freebsd_xdev.sh


_uboot_download_instructions ( ) {
    # Use TIs U-Boot sources that know about am335x processors
    # XXX TODO: Test with the master U-Boot sources from
    # denx.de; they claim to have merged the TI AM335X support.
    echo
    echo "Expected to see U-Boot sources in $UBOOT_SRC"
    echo "Use the following command to get the U-Boot sources"
    echo
    echo "git clone $1 $UBOOT_SRC"
    echo
    echo "Edit \$UBOOT_SRC in beaglebsd-config.sh if you want the sources in a different directory."
    echo "Run this script again after you have the U-Boot sources installed."
}

_uboot_test ( ) {
    # We use FreeBSD xdev tools to build U-Boot
    freebsd_xdev_test

    if [ ! -f "$1" ]; then
	_uboot_download_instructions "$2"
	exit 1
    fi
    if [ -z `which gmake` ]; then
	echo "U-Boot build requires 'gmake'"
	echo "Please install and re-run this script."
	exit 1
    fi

    echo "Found suitable U-Boot sources in $UBOOT_SRC"
}

#
# Test whether TI U-Boot sources are visible.
# If not, prompt the user to download them.
#
uboot_ti_test ( ) {
    _uboot_test \
	"$UBOOT_SRC/board/ti/am335x/Makefile" \
	"git://arago-project.org/git/projects/u-boot-am33x.git"
}

# uboot_patch: Apply patches to the U-Boot sources.
#
# $@: List of patch files to apply
uboot_patch ( ) {
    # TODO: Verify that _.uboot.patched lists the patch files
    # we expect.  If not, complain and exit.
    if [ -f ${UBOOT_SRC}/_.uboot.patched ]; then
	return 0
    fi

    if [ -f ${WORKDIR}/_.uboot.patched ]; then
	touch ${UBOOT_SRC}/_.uboot.patched
	return 0
    fi

    cd "$UBOOT_SRC"
    echo "Patching U-Boot. (Logging to ${WORKDIR}/_.uboot.patch.log)"
    for p in "$@"; do
	echo "   Applying patch $p"
	patch -N -p1 < $p >> ${WORKDIR}/_.uboot.patch.log 2>&1
    done
    echo "$@" > ${UBOOT_SRC}/_.uboot.patched
    rm -f ${WORKDIR}/_.uboot.configured
}

# uboot_configure
#
# $1: Name of U-Boot configuration to use.
uboot_configure ( ) {
    if [ -f ${WORKDIR}/_.uboot.configured ]; then
	return 0
    fi

    cd "$UBOOT_SRC"
    echo "Configuring U-Boot. (Logging to ${WORKDIR}/_.uboot.configure.log)"
    gmake CROSS_COMPILE=arm-freebsd- $1 > ${WORKDIR}/_.uboot.configure.log 2>&1
    echo "$1" > ${WORKDIR}/_.uboot.configured
    rm -f ${WORKDIR}/_.uboot.built
}

# uboot_build
#
uboot_build ( ) {
    if [ -f ${WORKDIR}/_.uboot.built ]; then
	echo "Using U-Boot from previous build."
	return 0
    fi

    cd "$UBOOT_SRC"
    echo "Building U-Boot. (Logging to ${WORKDIR}/_.uboot.build.log)"
    gmake CROSS_COMPILE=arm-freebsd- > ${WORKDIR}/_.uboot.build.log 2>&1
    touch ${WORKDIR}/_.uboot.built
}
