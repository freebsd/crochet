load_config ( ) {
    if [ -f $TOPDIR/config.sh ]; then
	echo "Loading local configuration"
	. $TOPDIR/config.sh
    else
	echo "No config.sh found."
	echo "Please copy config.sh.sample to config.sh and customize for your application"
	exit 1
    fi

    # Round down to sector multiple.
    SD_SIZE=$(( (SD_SIZE / 512) * 512 ))
}


# $1: name of board directory
#
board_init ( ) {
    BOARDDIR=${TOPDIR}/board/$1
    . $BOARDDIR/init.sh
}