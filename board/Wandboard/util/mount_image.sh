IMAGE=`ls ../../../work/*.img`
mdconfig -a -t vnode -f ${IMAGE} -u 0
mkdir -p /tmp/crochet_root
mkdir -p /tmp/crochet_freebsd
mount_msdosfs /dev/md0s1 /tmp/crochet_root
mount /dev/md0s2a /tmp/crochet_freebsd


