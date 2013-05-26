#
# Load the user configuration file.
#
# $1 - name of config file to load
#
load_config ( ) {
    # Used in old config files, before "option ImageSize" was added.
    MB=$((1000 * 1000))
    GB=$((1000 * $MB))

    if [ -f $1 ]; then
	echo "Loading configuration from $1"
	. $1
    else
	echo "Could not load $1"
	exit 1
    fi
}

#
# Invoke an option, which might be in one of the board
# directories or in the top-level option directory.
#
option ( ) {
    OPTION=$1
    shift
    for d in $BOARDDIRS ${TOPDIR}; do
	OPTIONDIR=$d/option/${OPTION}
	if [ -e ${OPTIONDIR}/setup.sh ]; then
	    echo "Option: $OPTION $@"
	    . $OPTIONDIR/setup.sh "$@"
	    OPTION=
	    OPTIONDIR=
	    return 0
	fi
    done

    echo "Cannot import option $OPTION."
    echo "No setup.sh found in either:"
    for d in $BOARDDIRS ${TOPDIR}; do
	echo "  * $d/option"
    done
    exit 1
}

