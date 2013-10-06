
PW=/usr/sbin/pw
LOGINUSER=$1

pw_create_account ( ) {
    if [ -n "${GZIPIMAGE}" ]; then
        echo "Adding user $LOGINUSER with password $LOGINUSER" 
        mkdir -p ${BOARD_FREEBSD_MOUNTPOINT}/usr/home/$LOGINUSER
        $PW useradd -n $LOGINUSER -s /bin/csh -g wheel -w yes -V ${BOARD_FREEBSD_MOUNTPOINT}/etc/ -d /usr/home/$LOGINUSER
    fi
}

# add a "crochet" account
strategy_add $PHASE_FREEBSD_BOARD_INSTALL pw_create_account

