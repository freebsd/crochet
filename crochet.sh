#!/bin/sh

#set -x # For debugging.

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
rm -rf ${WORKDIR}/strategy
mkdir -p ${WORKDIR}/strategy

MB=$((1000 * 1000))
GB=$((1000 * $MB))

# Load builder libraries.
. ${LIBDIR}/base.sh
. ${LIBDIR}/disk.sh
. ${LIBDIR}/freebsd.sh
. ${LIBDIR}/uboot.sh
. ${LIBDIR}/board.sh
. ${LIBDIR}/customize.sh

handle_trap ( ) {
    disk_unmount_all
    exit
}
trap handle_trap INT QUIT KILL EXIT

# Parse command-line options
args=`getopt c: $*`
if [ $? -ne 0 ]; then
    echo 'Usage: ...'
    exit 2
fi
set -- $args
while true; do
    case "$1" in
        -c)
            CONFIGFILE="$2"
            shift; shift
            ;;
        --)
            shift; break
            ;;
    esac
done

#
# Load user configuration
#
load_config

#
# This is where all the work gets done.
#
run_strategy

date
