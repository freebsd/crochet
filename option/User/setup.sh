
PW=/usr/sbin/pw
CHOWN=/usr/sbin/chown
AWK=/usr/bin/awk
HOME_DIR=/usr/home
USER_SHELL=/bin/sh

pw_create_account ( ) {
    echo "Adding user $1 with group $1 and password $1"
    mkdir -p ${BOARD_FREEBSD_MOUNTPOINT}${HOME_DIR}/$1
    $PW -V ${BOARD_FREEBSD_MOUNTPOINT}/etc/ useradd -n $1 -s ${USER_SHELL} -w yes -d ${HOME_DIR}/$1

    # Fetch the uid and gid from the target and use the numeric ids to set the ownership
    UGID=`$PW -V ${BOARD_FREEBSD_MOUNTPOINT}/etc/ usershow $1 | $AWK -F: '{ print $3 ":" $4 }'`
    $CHOWN $UGID ${BOARD_FREEBSD_MOUNTPOINT}${HOME_DIR}/$1
}

pw_add_user_to_group ( ) {
	if ! $PW -V ${BOARD_FREEBSD_MOUNTPOINT}/etc/ groupshow $2 >/dev/null 2>&1; then
		echo "Adding group $2"
		$PW -V ${BOARD_FREEBSD_MOUNTPOINT}/etc/ groupadd $2 >/dev/null 2>&1
	fi
    echo "Adding user $1 to group $2"
    $PW -V ${BOARD_FREEBSD_MOUNTPOINT}/etc/ groupmod $2 -m $1
}

# Add the specified account.
strategy_add $PHASE_FREEBSD_OPTION_INSTALL pw_create_account $1

if [ $# -gt 2 ]; then
	USER=$1
	shift
	for GROUP in $@; do
		# Group can be added by pkg, ensure this happens after pkg install in "option Package".
		PRIORITY=110 strategy_add $PHASE_FREEBSD_OPTION_INSTALL pw_add_user_to_group $USER $GROUP
	done
fi
