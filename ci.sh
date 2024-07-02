#! /bin/sh

# install git
echo "installing git"
pkg install -y git

# clone FreeBSD source
echo "cloning FreeBSD"
/bin/rm -rf /crochet/src
git clone https://github.com/freebsd/freebsd-src.git -b stable/13 /crochet/src 

