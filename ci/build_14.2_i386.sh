
#!/bin/sh

pwd
sudo pkg install -y git
sudo git clone -b releng/14.2 https://git.freebsd.org/src.git /usr/src
ls -lat /usr/src
sh crochet.sh -c ci/configs/config_i386.sh
rm -rf work/obj

