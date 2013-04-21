# Install a package
#
# Usage:
#  option Package emacs-nox11
# Make sure package database gets initialized.
option PackageInit

strategy_add $PHASE_FREEBSD_OPTION_INSTALL pkg -c ${BOARD_FREEBSD_MOUNTPOINT} -y $1

