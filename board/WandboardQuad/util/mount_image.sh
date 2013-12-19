IMAGE=`ls ../../../work/*.img`
mdconfig -a -t vnode -f ${IMAGE} -u 0
mkdir -p /tmp/imagemount_root
mkdir -p /tmp/imagemount_freebsd
mount_msdosfs /dev/md0s1 /tmp/imagemount_root
mount /dev/md0s2a /tmp/imagemount_freebsd


