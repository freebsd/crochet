#!/usr/bin/bash

# packages
sudo pkg install -y git

# source
/usr/bin/bash ci/git.sh

# build
PLATFORM_SCRIPT=ci/configs/config_i386.sh
echo "Building configuration $PLATFORM_SCRIPT"
sh crochet.sh -c $PLATFORM_SCRIPT -v
