# Install one or more packages
#
# Usage:
#  option Package apache mysql php

# Make sure package database gets initialized.
option PackageInit

package_install ( ) {
    echo "Installing packages (with dependencies): $1"
	pkg -c ${BOARD_FREEBSD_MOUNTPOINT} install -y -r ${_PACKAGE_REPO} $1
}

strategy_add $PHASE_FREEBSD_OPTION_INSTALL package_install "$@"
