# Install one or more packages
#
# Usage:
#  option Package apache mysql php

# Make sure package database gets initialized.
option PackageInit

export _PACKAGE_PKGS=$@

package_install ( ) {
    echo "Installing packages (with dependencies): ${_PACKAGE_PKGS}"
	pkg -c ${BOARD_FREEBSD_MOUNTPOINT} install -y -r ${_PACKAGE_REPO} ${_PACKAGE_PKGS}
}

strategy_add $PHASE_FREEBSD_OPTION_INSTALL package_install
