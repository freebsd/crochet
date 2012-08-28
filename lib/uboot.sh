
_uboot_download_instructions ( ) (
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
)

_uboot_test ( ) (
    if [ ! -f "$1" ]; then
	_uboot_download_instructions "$2"
	exit 1
    fi
    echo "Found suitable U-Boot sources in $UBOOT_SRC"
)

#
# Test whether TI U-Boot sources are visible.
# If not, prompt the user to download them.
#
uboot_ti_test ( ) (
    _uboot_test \
	"$UBOOT_SRC/board/ti/am335x/Makefile" \
	"git://arago-project.org/git/projects/u-boot-am33x.git" || exit 1
)

uboot_patch ( ) (
    if [ ! -f ${UBOOT_SRC}/_.uboot.patched ] && [ ! -f ${BUILDOBJ}/_.uboot.patched ]; then
	cd "$UBOOT_SRC"
	echo "Patching U-Boot. (Logging to ${BUILDOBJ}/_.uboot.patch.log)"
	for p in "$@"; do
	    echo "   Applying patch $p"
	    patch -N -p1 < $p >> ${BUILDOBJ}/_.uboot.patch.log 2>&1
	done

	rm -f ${BUILDOBJ}/_.uboot.configured
    fi
    touch ${UBOOT_SRC}/_.uboot.patched
)

uboot_configure ( ) (
    if [ ! -f ${BUILDOBJ}/_.uboot.configured ]; then
	cd "$UBOOT_SRC"
	echo "Configuring U-Boot. (Logging to ${BUILDOBJ}/_.uboot.configure.log)"
	gmake CROSS_COMPILE=arm-freebsd- $1 > ${BUILDOBJ}/_.uboot.configure.log 2>&1
	touch ${BUILDOBJ}/_.uboot.configured
	rm -f ${BUILDOBJ}/_.uboot.built
    fi
)

uboot_build ( ) (
    if [ ! -f ${BUILDOBJ}/_.uboot.built ]; then
	cd "$UBOOT_SRC"
	echo "Building U-Boot. (Logging to ${BUILDOBJ}/_.uboot.build.log)"
	gmake CROSS_COMPILE=arm-freebsd- > ${BUILDOBJ}/_.uboot.build.log 2>&1
	touch ${BUILDOBJ}/_.uboot.built
    else
	echo "Using U-Boot from previous build."
    fi
)
