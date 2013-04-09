#
# Load the user configuration file.
#
load_config ( ) {
    # Used in old config files, before "option ImageSize" was added.
    MB=$((1000 * 1000))
    GB=$((1000 * $MB))

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
	    echo "Importing option: $OPTION $@"
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

# Strategy List management

# Most of Crochet runs off of a "strategy" list of operations.  These
# operations are added to the strategy by the various configuration
# options.  After configuration, the strategy list is sorted and then
# run to actually do the work.

# The strategy list is kept in files under ${WORKDIR}/strategy;
# we need to clean that out before we start.
rm -rf ${WORKDIR}/strategy
mkdir -p ${WORKDIR}/strategy

# Each strategy item specifies a "phase" and a "priority".  Items are
# run in order sorted by phase, then priority, then by the order they
# were inserted.  In the strategy directory, there is a separate file
# for each phase (this allows items run by earlier phases to add stuff
# to later phases).

# DO NOT make up phase numbers.  If you need a new phase, add a
# symbolic name.  Phase numbers will change as the system evolves.

# There are a few phases that can only have a single item registered.
# These include "LWW" (Last Write Wins) in the name.  They are
# registered in the same way, but are handled internally a little
# differently.

# POST_CONFIG phase is a chance to update internal configuration
# after the user configuration has been completely read.
PHASE_POST_CONFIG=100

# CHECK is for testing that sources and necessary tools are available.
PHASE_CHECK=110

# BUILD phases are for actually compiling stuff
# Use BUILD_TOOLS for anything that's required by other build stages.
PHASE_BUILD_TOOLS=200
PHASE_BUILD_WORLD=210
PHASE_BUILD_KERNEL=220
PHASE_BUILD_OTHER=230

# Actually build the image and partition it.
# These are all LWW so they can be replaced by board or user code.
PHASE_IMAGE_BUILD_LWW=301
PHASE_PARTITION_LWW=311
PHASE_MOUNT_LWW=321

# PHASE_BOOT items run with cwd set to root of boot filesystem (if any).
PHASE_BOOT_START=500
PHASE_BOOT_INSTALL=510
PHASE_BOOT_DONE=599

# PHASE_FREEBSD items run with cwd set to root of freebsd filesystem
PHASE_FREEBSD_START=700
PHASE_FREEBSD_BASE_INSTALL=710
PHASE_FREEBSD_BOARD_INSTALL=720
PHASE_FREEBSD_OPTION_INSTALL=760
PHASE_FREEBSD_USER_CUSTOMIZATION=790
PHASE_FREEBSD_DONE=799

PHASE_UNMOUNT_LWW=891 # For internal use only; don't override this.

# PHASE_POST_UNMOUNT runs after the filesystems are unmounted.
PHASE_POST_UNMOUNT=900

# Prints the final status message with instructions for using the
# image.  Can be replaced by boards that need special instructions.
PHASE_GOODBYE_LWW=991


# This is the default priority used for all commands that
# don't specify one.  It should never be overwritten in
# the global environment.
PRIORITY=100


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

 # Appended to priority so sort will preserve insertion order
_STRATEGY_ADD_COUNTER=0
 # Last phase that was actually run
_CURRENT_PHASE=0

strategy_add ( ) {
    PHASE=$1
    # Forgetting or misspelling the phase argument is a common error.
    if [ $(($PHASE + 0)) -eq 0 ]; then
	echo "Error: Phase not specified: strategy_add $@"
	exit 1
    fi
    if [ $PHASE -le $_CURRENT_PHASE ]; then
	echo "Error: Inserting a strategy item for a phase that has already run"
	echo "    strategy_add $@"
	exit 1
    fi
    shift

    _STRATEGY_ADD_COUNTER=$(($_STRATEGY_ADD_COUNTER + 1))
    _PHASE_FILE=${WORKDIR}/strategy/${PHASE}.sh
    # LWW items are flagged with last digit '1'
    if [ $(($PHASE % 10)) -eq 1 ]; then
	rm -f ${_PHASE_FILE}
    fi
    cat >>${_PHASE_FILE} <<EOF
__run $_P OPTION=$OPTION OPTIONDIR=$OPTIONDIR BOARDDIR=$BOARDDIR $@
EOF
    echo ${PHASE} >> ${WORKDIR}/strategy/phases.txt
}

# Run all phases.
# We rescan the phases.txt file each time because an item
# can be registered for a later phase at any time, this might
# cause new phases to become active.
run_strategy ( ) {
    while true; do
	_LAST_PHASE=$_CURRENT_PHASE
	for P in `cat ${WORKDIR}/strategy/phases.txt | sort -n | uniq`; do
	    if [ $P -gt $_CURRENT_PHASE ]; then
		_CURRENT_PHASE=$P
		_PHASE_FILE=${WORKDIR}/strategy/${P}.sh
		# Sort by priority, then by insertion order.
		sort < ${_PHASE_FILE} > ${_PHASE_FILE}.sorted
		. ${_PHASE_FILE}.sorted
		break
	    fi
	done
	# If _CURRENT_PHASE did not progress, then we're done.
	if [ $_LAST_PHASE -eq $_CURRENT_PHASE ]; then
	    break
	fi
    done
}

# $1 - priority value for sorting; ignored
# $@ - command to run and arguments.
__run ( ) {
    # Set the cwd appropriately depending on the phase we're running.
    if [ $_CURRENT_PHASE -ge $PHASE_FREEBSD_START ] && [ $_CURRENT_PHASE -le $PHASE_FREEBSD_DONE ]; then
	cd ${BOARD_FREEBSD_MOUNTPOINT}
    elif [ $_CURRENT_PHASE -ge $PHASE_BOOT_START ] && [ $_CURRENT_PHASE -le $PHASE_BOOT_DONE ]; then
	cd ${BOARD_BOOT_MOUNTPOINT}
    else
	cd ${TOPDIR}
    fi
    shift
    eval $@
}