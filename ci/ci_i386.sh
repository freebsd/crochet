#!/bin/sh

# packages
sudo pkg install -y git

# source
/bin/sh ci/git.sh

# build
PLATFORM_SCRIPT=ci/configs/config_i386.sh
echo "building"
sh crochet.sh -c $PLATFORM_SCRIPT -v
