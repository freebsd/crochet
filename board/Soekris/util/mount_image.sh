IMAGE=`ls ../../../work/*.img`
mdconfig -a -t vnode -f ${IMAGE} -u 0
mkdir -p /tmp/imagemount
mount /dev/md0s1 /tmp/imagemount

