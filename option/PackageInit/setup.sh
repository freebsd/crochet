# Initialize the package setup:
#  * ensures that the package databases are initialized
#  * tries to upgrade the 'pkg' package
# In particular, 'option Package' invokes this
# to ensure the package system is set up.
#
# Usage:
#   option PackageInit http://my.local.pkg.repo/path
#
# The argument is used to create a repo config file.
#
# Usage:
#   option PackageInit
#
# With no argument, it does the same initialization but
# uses the existing (or default) FreeBSD repo setting.

if [ -n "$1" ]; then
    export _PACKAGE_SITE=$1
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
	if [ -n "${_PACKAGE_SITE}" ]; then
		cat <<EOF > ${BOARD_FREEBSD_MOUNTPOINT}/etc/pkg/tmp.conf
tmp: {
  url: "${_PACKAGE_SITE}",
  enabled: yes
}
EOF
		export _PACKAGE_REPO=tmp
	else
		export _PACKAGE_REPO=FreeBSD
	fi
    pkg -c ${BOARD_FREEBSD_MOUNTPOINT} update -r ${_PACKAGE_REPO}
    pkg -c ${BOARD_FREEBSD_MOUNTPOINT} install -y -r ${_PACKAGE_REPO} pkg
    pkg -c ${BOARD_FREEBSD_MOUNTPOINT} upgrade -r ${_PACKAGE_REPO}
}

package_init_cleanup ( ) {
	rm 	${BOARD_FREEBSD_MOUNTPOINT}/etc/pkg/tmp.conf
}

# Only register the package init functions once.
if [ -z "$_PACKAGE_INIT" ]; then
    strategy_add $PHASE_CHECK package_test
    # Ensure this happens before any "option Package"
    PRIORITY=50 strategy_add $PHASE_FREEBSD_OPTION_INSTALL package_init
    # Ensure this happens after any "option Package"
    PRIORITY=150 strategy_add $PHASE_FREEBSD_OPTION_INSTALL package_init_cleanup
    _PACKAGE_INIT=t
fi
