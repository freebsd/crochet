# Install one or more packages
#
# Usage:
#  option Package apache mysql php

# Make sure package database gets initialized.
option PackageInit

for p in $@; do
    strategy_add $PHASE_FREEBSD_OPTION_INSTALL pkg -c . -y $p
done
