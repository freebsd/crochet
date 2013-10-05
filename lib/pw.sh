PW=/usr/sbin/pw

pw_create_crochet_account ( ) {
    pw_create_account "crochet" 
}

pw_create_account ( ) {
#    echo "${BOARD_FREEBSD_MOUNTPOINT}/etc/"
    echo "Adding user $1 with password $1" 
    mkdir -p ${BOARD_FREEBSD_MOUNTPOINT}/usr/home/$1
    $PW useradd -n $1 -s /bin/csh -g wheel -w yes -V ${BOARD_FREEBSD_MOUNTPOINT}/etc/ -d /usr/home/$1
}
