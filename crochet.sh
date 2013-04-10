#!/bin/sh
set -e
echo 'Starting at '`date`

# General configuration and useful definitions
TOPDIR=`cd \`dirname $0\`; pwd`
LIBDIR=${TOPDIR}/lib
WORKDIR=${TOPDIR}/work
CONFIGFILE=config.sh

# Initialize the work directory, clean out old logs and strategies.
mkdir -p ${WORKDIR}
rm -f ${WORKDIR}/*.log

# Load builder libraries.
. ${LIBDIR}/base.sh
. ${LIBDIR}/disk.sh
. ${LIBDIR}/freebsd.sh
. ${LIBDIR}/uboot.sh
. ${LIBDIR}/board.sh
. ${LIBDIR}/customize.sh

# Parse command-line options
args=`getopt b:c: $*`
if [ $? -ne 0 ]; then
    echo 'Usage: ...'
    exit 2
fi
set -- $args
while true; do
    case "$1" in
	-b)
	    board_setup $2
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
	    exit 0
    esac
done

#
# Load user configuration
#
load_config

#
# What to do when things go wrong.
#
handle_trap ( ) {
    disk_unmount_all
    exit 2
}
trap handle_trap INT QUIT KILL EXIT

#
# This is where all the work gets done.
#
run_strategy

date
