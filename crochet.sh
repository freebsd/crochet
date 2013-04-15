#!/bin/sh
set -e
echo 'Starting at '`date`

# General configuration and useful definitions
TOPDIR=`cd \`dirname $0\`; pwd`
LIBDIR=${TOPDIR}/lib
WORKDIR=${TOPDIR}/work
CONFIGFILE=
BOARD=

# Initialize the work directory, clean out old logs and strategies.
mkdir -p ${WORKDIR}
rm -f ${WORKDIR}/*.log

# Load utility libraries.
. ${LIBDIR}/base.sh
. ${LIBDIR}/disk.sh
. ${LIBDIR}/freebsd.sh
. ${LIBDIR}/uboot.sh
. ${LIBDIR}/board.sh
. ${LIBDIR}/customize.sh

crochet_usage ( ) {
    echo "Usage: $0 -b <board> -c <configfile>"
    echo " -b <board>: Load standard configuration for board"
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

#
# What to do when things go wrong.
#
handle_trap ( ) {
    disk_unmount_all
    exit 2
}
trap handle_trap INT QUIT KILL EXIT

#
# Run the strategy and actually do all of the work.
#
run_strategy

date
