#!/usr/local/bin/bash

# packages
sudo pkg install -y git

# source
/usr/local/bin/bash ci/git.sh

# build
PLATFORM_SCRIPT=ci/configs/config_soekris.sh
echo "Building configuration $PLATFORM_SCRIPT"
sh crochet.sh -c $PLATFORM_SCRIPT -v
