#!/bin/sh

# packages
sudo pkg install -y git python3 u-boot-rpi2 rpi-firmware

# source
/bin/sh ci/git.sh

# build
PLATFORM_SCRIPT=ci/configs/config_rpi2.sh
echo "building"
sh crochet.sh -c $PLATFORM_SCRIPT -v
