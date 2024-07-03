#!/bin/bash

# packages
sudo pkg install -y git python3 u-boot-rpi

# source
/bin/bash ci/git.sh

# build
PLATFORM_SCRIPT=ci/configs/config_rpi.sh
echo "Building configuration $PLATFORM_SCRIPT"
sh crochet.sh -c $PLATFORM_SCRIPT -v
