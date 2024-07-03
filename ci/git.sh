#!/bin/bash

# vars
SOURCE_DIR=/crochet/src
SOURCE_URL=https://github.com/freebsd/freebsd-src.git
SOURCE_BRANCH=stable/13

# install git
echo "installing git"
sudo pkg install -y git

# clone FreeBSD source
sudo git config --global http.version HTTP/1.1
if [ -d $SOURCE_DIR/.git ]; then 
    echo "updating FreeBSD"
    pushd 
    cd $SOURCE_DIR; 
    sudo git pull; 
    popd; 
else
    echo "cloning FreeBSD from $SOURCE_BRANCH branch $SOURCE_BRANCH into $SOURCE_DIR"
    sudo git clone $SOURCE_URL -b $SOURCE_BRANCH $SOURCE_DIR 
fi


