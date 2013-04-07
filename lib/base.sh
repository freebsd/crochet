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
    BOARDOPTIONDIR=${BOARDDIR}/option/${OPTION}
    if [ -e ${BOARDOPTIONDIR}/setup.sh ]; then
	OPTIONDIR=${BOARDOPTIONDIR}
	echo "Importing board-specific option: $OPTION $@"
	. $OPTIONDIR/setup.sh "$@"
    elif [ -e ${OPTIONDIR}/setup.sh ]; then
	echo "Importing option: $OPTION $@"
	. $OPTIONDIR/setup.sh "$@"
    else
	echo "Cannot import option $OPTION."
	echo "No setup.sh found in either:"
	echo "  * ${OPTIONDIR} or"
	echo "  * ${BOARDOPTIONDIR}"
	exit 1
    fi

    OPTION=
    OPTIONDIR=
    BOARDOPTIONDIR=
}

#
# Add something to the strategy list to be executed
# as part of the main Crochet strategy run.

echo > ${WORKDIR}/strategy_unsorted.sh

# This is the default priority used for all commands that
# don't specify one.  It should never be overwritten in
# the global environment.
PRIORITY=100

# Most of Crochet runs off of a "strategy" list of
# operations.  These operations are added to the strategy
# by the various configuration options.  After configuration,
# the entire strategy list is sorted and then run to actually
# do the work.

# Each strategy item specifies a "phase" and a "priority".
# Items are run in order sorted by phase, then priority,
# then by the order they were inserted.
# DO NOT make up phase numbers.  If you need a new phase,
# add a symbolic name.  Phase numbers will change as the
# system evolves.

# There are a few phases that can only have a single item
# registered.  These include "LWW" (Last Write Wins) in
# the name.  They are registered in the same way, but
# are handled internally a little differently.

# CHECK phase is for testing that sources and necessary
# tools are available
PHASE_CHECK=100

PHASE_TEST_LWW=101

# BUILD phases are for actually compiling stuff
PHASE_BUILD_TOOLS=200
PHASE_BUILD_WORLD=210
PHASE_BUILD_KERNEL=220
PHASE_BUILD_OTHER=230

# Actually build the image and partition it
PHASE_IMAGE_BUILD_LWW=301
PHASE_PARTITION_LWW=311
PHASE_MOUNT_LWW=321

# PHASE_BOOT items run with cwd set to root of boot filesystem (if any)
PHASE_BOOT_START=500
PHASE_BOOT_INSTALL=510
PHASE_BOOT_DONE=599

# PHASE_FREEBSD items run with cwd set to root of freebsd filesystem being constructed
PHASE_FREEBSD_START=700
PHASE_FREEBSD_BASE_INSTALL=710
PHASE_FREEBSD_EXTRA_INSTALL=720
PHASE_FREEBSD_LATE_CUSTOMIZATION=790
PHASE_FREEBSD_DONE=799

PHASE_UNMOUNT_LWW=891 # For internal use only; don't override this.

# PHASE_POST_UNMOUNT runs after the filesystems are unmounted.
PHASE_POST_UNMOUNT=900


# $1 - Phase to run this in.
# $@ - shell function and options
#
# To register an operation to be run in PHASE_X with default priority:
#    strategy_add $PHASE_X foofunc fooarg1 fooarg2
#
# To override PRIORITY (lower is earlier; default is 100):
#    PRIORITY=70 strategy_add $PHASE_X foofunc fooargs
#
# If phase is one of the special LWW phases, then only the last
# function registered for that phase will actually be run.  Otherwise,
# all registrations for a phase are run.

_STRATEGY_ADD_COUNTER=0
strategy_add ( ) {
    PHASE=$1
    if [ $(($PHASE + 0)) -eq 0 ]; then
	echo "Error: Phase not specified: strategy_add $@"
	exit 1
    fi
    shift

    _STRATEGY_ADD_COUNTER=$(($_STRATEGY_ADD_COUNTER + 1))
    CMD="$@"
    if [ $(($PHASE % 10)) -eq 1 ]; then
	# Overwrite the file with the command for this phase.
	echo $CMD >${WORKDIR}/strategy_$PHASE.sh
	# Arrange for that file to get executed just once.
	CMD="__once ${WORKDIR}/strategy_$PHASE.sh"
    fi
    _P0=$(($PHASE * 1000000 + ${PRIORITY} * 1000 + $_STRATEGY_ADD_COUNTER))
    _P=`printf '%09d' $_P0`
    cat >>${WORKDIR}/strategy_unsorted.sh <<EOF
__run $_P OPTION=$OPTION OPTIONDIR=$OPTIONDIR BOARDDIR=$BOARDDIR $CMD
EOF
}

# $1 -- file with commands to be run exactly once.
# This just renames the file to $1.finished to prevent it being
# run again.
__once ( ) {
    if [ -f $1 ]; then
	. $1
	mv $1 $1.finished
    fi
}


# Run 
# $1 - root of installed tree
run_strategy ( ) {
    cd $1
    sort < ${WORKDIR}/strategy_unsorted.sh > ${WORKDIR}/strategy_sorted.sh
    . ${WORKDIR}/strategy_sorted.sh
}

# $1 - priority value, including encoded phase
# $@ - command to run and arguments.
__run ( ) {
    # Recover the phase from the sort key (we don't care about priority here).
    PHASE=$((`echo $1 | sed 's/^0*//'` / 1000000))
    # Set the cwd appropriately depending on the phase we're running.
    if [ $PHASE -ge $PHASE_FREEBSD_START ] && [ $PHASE -le $PHASE_FREEBSD_DONE ]; then
	cd ${BOARD_FREEBSD_MOUNTPOINT}
    elif [ $PHASE -ge $PHASE_BOOT_START ] && [ $PHASE -le $PHASE_BOOT_DONE ]; then
	cd ${BOARD_BOOT_MOUNTPOINT}
    else
	cd ${TOPDIR}
    fi
    shift
    eval $@
}