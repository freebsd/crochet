# Install one or more packages
#
# Usage:
#  option Package apache mysql php

# Make sure package database gets initialized.
option PackageInit

package_install ( ) {
    echo "Installing packages (with dependencies): $@"
	pkg -c ${BOARD_FREEBSD_MOUNTPOINT} install -y -r ${_PACKAGE_REPO} $@
}

strategy_add $PHASE_FREEBSD_OPTION_INSTALL package_install "$@"
