load_config ( ) {
    if [ -f $TOPDIR/config.sh ]; then
	echo "Loading local configuration"
	. $TOPDIR/config.sh
    else
	echo "No config.sh found."
	echo "Please copy config.sh.sample to config.sh and customize for your application"
	exit 1
    fi

    if [ -z "$BOARDDIR" ]; then
	echo "No board setup?"
	echo "Make sure a suitable board_setup command appears at the top of config.sh"
	exit 1
    fi
}
