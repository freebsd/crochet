#!/bin/sh

/bin/sh ci/git.sh

# build
PLATFORM_SCRIPT=ci/configs/config_rpi.sh
echo "building"
sh crochet.sh -c $PLATFORM_SCRIPT -v
