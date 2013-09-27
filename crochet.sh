#!/bin/sh
set -e
echo 'Starting at '`date`

# General configuration and useful definitions
TOPDIR=`cd \`dirname $0\`; pwd`
LIBDIR=${TOPDIR}/lib
WORKDIR=${TOPDIR}/work
CONFIGFILE=
BOARD=

# Load utility libraries.
. ${LIBDIR}/strategy.sh  # Must go first
. ${LIBDIR}/board.sh
. ${LIBDIR}/config.sh
. ${LIBDIR}/customize.sh
. ${LIBDIR}/disk.sh
. ${LIBDIR}/freebsd.sh
. ${LIBDIR}/uboot.sh

crochet_usage ( ) {
    echo "Usage: sudo $0 [-b <board>|-c <configfile>]"
    echo " -b <board>: Load standard configuration for board"
    echo "    (Equivalent to loading a config file that contains"
    echo "    only a single board_setup command.)"
    echo " -c <file>: Load configuration from file"
    exit 2
}

# Parse command-line options
args=`getopt b:c: $*`
if [ $? -ne 0 ]; then
    crochet_usage
fi
set -- $args
while true; do
    case "$1" in
	-b)
	    BOARD="$2"
	    shift; shift
	    ;;
        -c)
            CONFIGFILE="$2"
            shift; shift
            ;;
        --)
            shift; break
            ;;
	*)
	    crochet_usage
    esac
done

#
# Load user configuration:  This builds the strategy.
#
if [ -z "$BOARD" ] && [ -z "$CONFIGFILE" ]; then
    crochet_usage
fi
if [ -n "$BOARD" ]; then
    board_setup $BOARD
fi
if [ -n "$CONFIGFILE" ]; then
    load_config $CONFIGFILE
fi

# Initialize the work directory, clean out old logs.
mkdir -p ${WORKDIR}
rm -f ${WORKDIR}/*.log

#
# What to do when things go wrong.
#
handle_trap ( ) {
    disk_unmount_all
    exit 2
}
trap handle_trap INT QUIT KILL EXIT

#
# Run the strategy to do all of the work.
#
run_strategy

echo 'Finished at '`date`
