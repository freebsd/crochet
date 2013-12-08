mdconfig -a -t vnode -f ../../../work/FreeBSD-arm-11.0-WANDBOARD-QUAD.img -u 0
mkdir -p /tmp/imagemount
mount_msdosfs /dev/md0s1 /tmp/imagemount

