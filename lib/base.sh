load_config ( ) {
    if [ -f $CONFIGDIR/config.sh ]; then
	echo "Loading configuration values"
	. $CONFIGDIR/config.sh
    fi

    echo "Loading configuration values"
    . $TOPDIR/beaglebsd-config.sh

    if [ -f $TOPDIR/beaglebsd-config-local.sh ]; then
	echo "Loading local configuration overrides"
	. $TOPDIR/beaglebsd-config-local.sh
    fi

    # Round down to sector multiple.
    SD_SIZE=$(( (SD_SIZE / 512) * 512 ))
}
