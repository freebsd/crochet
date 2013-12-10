mdconfig -a -t vnode -f ../../../work/FreeBSD-arm-11.0-WANDBOARD-QUAD.img -u 0
mkdir -p /tmp/imagemount_root
mkdir -p /tmp/imagemount_freebsd
mount_msdosfs /dev/md0s1 /tmp/imagemount_root
mount /dev/md0s2a /tmp/imagemount_freebsd


