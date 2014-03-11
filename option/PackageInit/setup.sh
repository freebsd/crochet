# Initialize the package setup:
#  * ensures that the package databases are initialized
#  * tries to upgrade the 'pkg' package
# In particular, 'option Package' invokes this
# to ensure the package system is set up.
#
# Usage:
#   option PackageInit http://my.local.pkg.repo/path
#
# The argument is used to initialize PACKAGESITE.
#
# Usage:
#   option PackageInit
#
# With no argument, it does the same initialization but
# uses the existing (or default) PACKAGESITE setting.

if [ -n "$1" ]; then
    echo "Set PACKAGESITE=$1"
    PACKAGESITE=$1
    export PACKAGESITE
fi

package_test ( ) {
    if pkg -v >/dev/null 2>&1; then
	true
    else
	echo "pkg not available on the build system"
	exit 1
    fi

}

package_init ( ) {
    echo "Initializing package system"
    pkg -c ${BOARD_FREEBSD_MOUNTPOINT} update
    pkg -c ${BOARD_FREEBSD_MOUNTPOINT} install -y pkg
    pkg -c ${BOARD_FREEBSD_MOUNTPOINT} upgrade
}

# Only register the package init functions once.
if [ -z "$_PACKAGE_INIT" ]; then
    strategy_add $PHASE_CHECK package_test
    # Ensure this happens before any "option Package"
    PRIORITY=50 strategy_add $PHASE_FREEBSD_OPTION_INSTALL package_init
    _PACKAGE_INIT=t
fi
