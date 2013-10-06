
PW=/usr/sbin/pw

pw_create_account ( ) {
    echo "Adding user $1 with password $1"
    mkdir -p ${BOARD_FREEBSD_MOUNTPOINT}/usr/home/$1
    $PW useradd -n $1 -s /bin/csh -g wheel -w yes -V ${BOARD_FREEBSD_MOUNTPOINT}/etc/ -d /usr/home/$1
}

# Add the specified account.
strategy_add $PHASE_FREEBSD_BOARD_INSTALL pw_create_account $1

