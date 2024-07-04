#!/usr/local/bin/bash

# packages
sudo pkg install -y git python3 u-boot-rpi2 rpi-firmware

# source
/usr/local/bin/bash ci/git.sh

# build
PLATFORM_SCRIPT=ci/configs/config_rpi2.sh
echo "Building configuration $PLATFORM_SCRIPT"
sudo sh crochet.sh -c $PLATFORM_SCRIPT -v
