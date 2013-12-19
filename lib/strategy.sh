# Strategy List management

# TODO: Rename 'strategy' to something more appropriate, since
# this has nothing to do with the 'strategy pattern.'  That
# will involve renaming this file and a lot of internal variables
# and functions...

# Most of Crochet runs off of a "strategy list" of operations.  The
# configuration hooks all invoke strategy_add to add operations to the
# strategy list.  After configuration, the strategy list is sorted and
# then the items are run to actually do the work.

# The strategy list for this run is kept in ${STRATEGYDIR}.
# Note: ${STRATEGYDIR} cannot be under ${WORKDIR} since WORKDIR
# hasn't been set yet.

# Clean out old strategies.
STRATEGYBASE=/tmp/crochet/strategy
if [ -d ${STRATEGYBASE} ]
then
    find ${STRATEGYBASE} -maxdepth 1 -ctime +3 | xargs rm -rf
fi
mkdir -p ${STRATEGYBASE}
# Create a new dir for this run.
# Including timestamp in the dirname simplifies debugging.
_DATE=`date +%Y.%m.%d.%H.%M.%S`
STRATEGYDIR=`mktemp -d ${STRATEGYBASE}/${_DATE}-XXXXXX`

# Each strategy item specifies a "phase" and a "priority".  Items are
# run in order sorted by phase, then priority, then by the order they
# were inserted.  In the strategy directory, there is a separate file
# for each phase (this allows items run by earlier phases to add stuff
# to later phases).

# DO NOT use numbers in the argument to strategy_add.  If you need a
# new phase, add a symbolic name.  The specific phase numbers will
# change as the system evolves.  If you just need to run something
# "a little earlier" or "a little later", try fudging the priority
# instead of adding a new phase.  If you do need a new phase, let
# me know; I'm curious what I overlooked.

# There are a few phases that can only have a single item registered.
# These include "LWW" (Last Write Wins) in the name.  They use
# the same registration interface, but only the last registration
# will actually get run.

# POST_CONFIG phase is a chance to update internal configuration
# after the user configuration has been completely read but before
# any real work is attempted.
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
# Basic freebsd installworld, which is registered in lib/board.sh but can be overridden
PHASE_FREEBSD_INSTALLWORLD_LWW=711
# "Board" is reserved for board definitions
PHASE_FREEBSD_BOARD_INSTALL=720
# "Option" is reserved for options
PHASE_FREEBSD_OPTION_INSTALL=760
# "User" is reserved for user customization and should not be used
# by any board or option definition.
PHASE_FREEBSD_USER_CUSTOMIZATION=790
PHASE_FREEBSD_DONE=799

# Do not override: This is for the lib/disk.sh "unmount everything" function.
# TODO: This should go away in favor of PHASE_UNMOUNT
PHASE_UNMOUNT_LWW=891

# TODO: Rework unmount handling so that mount functions add an
# operation to PHASE_UNMOUNT.  That should remove the need for
# lib/disk.sh to track what partitions have been mounted.
PHASE_UNMOUNT=892

# PHASE_POST_UNMOUNT runs after the filesystems are unmounted.
PHASE_POST_UNMOUNT=900

# Prints the final status message with instructions for using the
# image.  Can be replaced by boards that need special instructions.
PHASE_GOODBYE_LWW=991

# This is the default priority used for all commands that
# don't specify one.
PRIORITY=100

# $1 - Phase to run this in.
# $@ - shell function and options
#
# To register an operation to be run in PHASE_X with default priority:
#    strategy_add $PHASE_X foofunc fooarg1 fooarg2
#
# To override PRIORITY (lower is earlier; default is 100):
#    PRIORITY=70 strategy_add $PHASE_INSTALL_FROGS addfrogs earlyfrogs
#    PRIORITY=200 strategy_add $PHASE_INSTALL_FROGS addfrogs latefrogs
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
    _P=`printf '%03d%03d' ${PRIORITY} ${_STRATEGY_ADD_COUNTER}`
    _PHASE_FILE=${STRATEGYDIR}/${PHASE}.sh
    # LWW items are flagged with last digit '1'
    if [ $(($PHASE % 10)) -eq 1 ]; then
        rm -f ${_PHASE_FILE}
    fi
    cat >>${_PHASE_FILE} <<EOF
__run $_P OPTION=$OPTION OPTIONDIR=$OPTIONDIR BOARDDIR=$BOARDDIR $@
EOF
    echo ${PHASE} >> ${STRATEGYDIR}/phases.txt
}

#
# $1 - Numeric ID of phase to run
#
run_phase ( ) {
    _PHASE_FILE=${STRATEGYDIR}/${P}.sh
    # Sort by priority, then by insertion order.
    sort < ${_PHASE_FILE} > ${_PHASE_FILE}.sorted
    if [ $VERBOSE -gt 0 ]; then
	# TODO: Print a description, not just the number.
	echo "====================> Phase $P <===================="
    fi
    . ${_PHASE_FILE}.sorted
}

# Run all phases.
# We rescan the phases.txt file each time because an item
# can be registered for a later phase at any time, this might
# cause new phases to become active.
run_strategy ( ) {
    while true; do
        _LAST_PHASE=$_CURRENT_PHASE
        for P in `cat ${STRATEGYDIR}/phases.txt | sort -n | uniq`; do
            if [ $P -gt $_CURRENT_PHASE ]; then
                _CURRENT_PHASE=$P
		run_phase ${P}
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
    if [ $VERBOSE -gt 0 ]; then
	echo "Running: " $@
    fi
    eval $@
}
