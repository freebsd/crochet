load_config ( ) {
    if [ -f $CONFIGFILE ]; then
	echo "Loading configuration from $CONFIGFILE"
	. $CONFIGFILE
    else
	echo "Could not load $CONFIGFILE"
	echo "Please"
	echo "  $ cp config.sh.sample $CONFIGFILE"
	echo "and customize for your application"
	exit 1
    fi

    if [ -z "$BOARDDIR" ]; then
	echo "No board setup?"
	echo "Make sure a suitable board_setup command appears at the top of ${CONFIGFILE}"
	exit 1
    fi
}

option ( ) {
    OPTION=$1
    shift
    OPTIONDIR=${TOPDIR}/option/${OPTION}
    if [ ! -e ${OPTIONDIR}/setup.sh ]; then
	echo "Cannot setup option $OPTION."
	echo "No setup.sh in ${OPTIONDIR}."
	exit 1
    fi
    . $OPTIONDIR/setup.sh "$@"
    echo "Imported option $OPTION"
}

#
# Options can hook any of the following points in the
# image construction:
#   * post-world:  After FreeBSD world is installed,
#                  after board-specific customization,
#                  but before the user customize hook.
#
# NOTE: These following hook functions are most definitely not
# intended for user customizations, and should never be called
# directly from config.sh.
#
# TODO: As new options are implemented, evaluate what hooks
# are provided here and add new hooks as needed.
#

echo > ${WORKDIR}/options_post_installworld.sh

# $@ - shell function and options
add_option_post_installworld ( ) {
    cat >>${WORKDIR}/options_post_installworld.sh <<EOF
echo "Performing post-installworld $OPTION"
OPTIONDIR=$OPTIONDIR $@
EOF
}

# $1 - root of installed tree
run_options_post_installworld ( ) {
    cd $1
    if /bin/sh -x ${WORKDIR}/options_post_installworld.sh; then
	true # Everything went well.
    else
	echo "Post-installworld options failed."
	exit 1
    fi
}
