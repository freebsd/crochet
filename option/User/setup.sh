
PW=/usr/sbin/pw
CHOWN=/usr/sbin/chown
AWK=/usr/bin/awk
HOME_DIR=/usr/home

pw_create_account ( ) {
    echo "Adding user $1 with password $1"
    mkdir -p ${BOARD_FREEBSD_MOUNTPOINT}${HOME_DIR}/$1
    $PW -V ${BOARD_FREEBSD_MOUNTPOINT}/etc/ useradd -n $1 -s /bin/csh -g wheel -w yes -d ${HOME_DIR}/$1

    # Fetch the uid and gid from the target and use the numeric ids to set the ownership
    UGID=`$PW -V ${BOARD_FREEBSD_MOUNTPOINT}/etc/ usershow $1 | $AWK -F: '{ print $3 ":" $4 }'`
    $CHOWN $UGID ${BOARD_FREEBSD_MOUNTPOINT}${HOME_DIR}/$1
}

# Add the specified account.
strategy_add $PHASE_FREEBSD_BOARD_INSTALL pw_create_account $1

