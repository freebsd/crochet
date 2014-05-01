
PW=/usr/sbin/pw
CHOWN=/usr/sbin/chown
AWK=/usr/bin/awk

pw_create_account ( ) {
    echo "Adding user $1 with password $1"
    mkdir -p ${BOARD_FREEBSD_MOUNTPOINT}/usr/home/$1
    $PW useradd -n $1 -s /bin/csh -g wheel -w yes -V ${BOARD_FREEBSD_MOUNTPOINT}/etc/ -d /usr/home/$1

    # Fetch the uid and gid from the target and use the numeric ids to set the ownership
    UGID=`$PW usershow $1 -V ${BOARD_FREEBSD_MOUNTPOINT}/etc/ | $AWK -F: '{ print $3 ":" $4 }'`
    $CHOWN $UGID ${BOARD_FREEBSD_MOUNTPOINT}/usr/home/$1
}

# Add the specified account.
strategy_add $PHASE_FREEBSD_BOARD_INSTALL pw_create_account $1

