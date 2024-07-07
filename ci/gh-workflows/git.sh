#!/usr/local/bin/bash

# vars
SOURCE_DIR=/crochet/src
SOURCE_URL=https://github.com/freebsd/freebsd-src.git
SOURCE_BRANCH=stable/13

# install git
echo "Installing git"
sudo pkg install -y git

# clone FreeBSD source
sudo git config --global http.version HTTP/1.1
sudo git config --global http.postBuffer 524288000
sudo git config --global core.compression 0
if [ -d $SOURCE_DIR/.git ]; then 
    echo "Updating FreeBSD source at $SOURCE_DIR"
    cd $SOURCE_DIR
    sudo git pull
else
    echo "Cloning FreeBSD source from $SOURCE_BRANCH branch $SOURCE_BRANCH into $SOURCE_DIR"
    sudo git clone --depth=1 $SOURCE_URL -b $SOURCE_BRANCH $SOURCE_DIR 
fi


