#!/bin/sh

# vars
SOURCE_DIR=/crochet/src
SOURCE_URL=https://github.com/freebsd/freebsd-src.git
SOURCE_BRANCH=stable/13

# install git
echo "installing git"
sudo pkg install -y git

# clone FreeBSD source
echo "cloning FreeBSD from $SOURCE_BRANCH branch $SOURCE_BRANCH into $SOURCE_DIR"
sudo /bin/rm -rf $SOURCE_DIR
sudo git clone $SOURCE_URL -b $SOURCE_BRANCH $SOURCE_DIR
