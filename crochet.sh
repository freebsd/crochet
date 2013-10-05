#!/bin/sh
set -e
echo 'Starting at '`date`

# General configuration and useful definitions
TOPDIR=`cd \`dirname $0\`; pwd`
LIBDIR=${TOPDIR}/lib
WORKDIR=${TOPDIR}/work
CONFIGFILE=
BOARD=
EMAIL=
UPDATE_SOURCE=

# Load utility libraries.
. ${LIBDIR}/strategy.sh  # Must go first
. ${LIBDIR}/board.sh
. ${LIBDIR}/config.sh
. ${LIBDIR}/customize.sh
. ${LIBDIR}/disk.sh
. ${LIBDIR}/freebsd.sh
. ${LIBDIR}/uboot.sh
. ${LIBDIR}/email.sh
. ${LIBDIR}/subversion.sh
. ${LIBDIR}/gzip.sh
. ${LIBDIR}/os.sh
. ${LIBDIR}/pw.sh

crochet_usage ( ) {
    echo "Usage: sudo $0 [-b <board>|-c <configfile>]"
    echo " -b <board>: Load standard configuration for board"
    echo "    (Equivalent to loading a config file that contains"
    echo "    only a single board_setup command.)"
    echo " -c <file>: Load configuration from file"
    echo " -e <email>: Email address to receive build status"
    echo " -u: Update source tree"
    exit 2
}

# Parse command-line options
args=`getopt ub:c:e: $*`
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
        -e)
            EMAIL="$2"
            shift; shift
            ;;
        -u)
            UPDATE_SOURCETREE=yes
            shift
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
# The build config
#
BUILDCONFIG="TOPDIR: ${TOPDIR}
SOURCE TREE: ${FREEBSD_SRC}"

#
# What to do when things go wrong.
#
handle_trap ( ) {
    disk_unmount_all
    email_status "${BUILDCONFIG}" "Crochet build failed"
    exit 2
}
trap handle_trap INT QUIT KILL

if [ -n "${UPDATE_SOURCETREE}" ]; then
    update_sourcetree
fi

#
# we're starting
#
BUILDCONFIG="TOPDIR: ${TOPDIR}
SOURCE TREE: ${FREEBSD_SRC}"

email_status "${BUILDCONFIG}" "Crochet build commenced"

#
# Run the strategy to do all of the work.
#
run_strategy

#
# we're done
#
email_status "${BUILDCONFIG}" "Crochet build finished"

echo 'Finished at `date`'

