IMAGE=`ls ../../../work/*.img`
mdconfig -a -t vnode -f ${IMAGE} -u 0
mkdir -p /tmp/crochet_fat
mkdir -p /tmp/crochet_freebsd
mount_msdosfs /dev/md0s2 /tmp/crochet_fat
mount /dev/md0s3 /tmp/crochet_freebsd


