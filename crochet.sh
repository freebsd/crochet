#!/bin/sh
set -e
echo 'Starting at '`date`

# General configuration and useful definitions
TOPDIR=`cd \`dirname $0\`; pwd`
LIBDIR=${TOPDIR}/lib
WORKDIR=${TOPDIR}/work
CONFIGFILE=
BOARD=
UPDATE_SOURCE=

DEBUG=0

# Load utility libraries: strategy.sh must go first
. ${LIBDIR}/strategy.sh
# Rest in alphabetic order
. ${LIBDIR}/board.sh
. ${LIBDIR}/config.sh
. ${LIBDIR}/customize.sh
. ${LIBDIR}/disk.sh
. ${LIBDIR}/email.sh
. ${LIBDIR}/freebsd.sh
. ${LIBDIR}/os.sh
. ${LIBDIR}/subversion.sh
. ${LIBDIR}/uboot.sh

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
args=`getopt b:c:de:u $*`
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
        -d)
            DEBUG=1
            shift
            ;;
        -e)
            option Email "$2"
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

os_determine_os_version
board_generate_image_name

# Initialize the work directory, clean out old logs.
mkdir -p ${WORKDIR}
rm -f ${WORKDIR}/*.log

# Details for the email reports
BUILDCONFIG="TOPDIR: ${TOPDIR}
SOURCE TREE: ${FREEBSD_SRC}"

#
# What to do when things go wrong.
#
handle_trap ( ) {
    disk_unmount_all

    email_status "${BUILDCONFIG}" "Crochet build failed"

    echo
    echo 'ERROR: Exiting at '`date`
    echo
    exit 2
}
trap handle_trap INT QUIT KILL

if [ -n "${UPDATE_SOURCETREE}" ]; then
    update_sourcetree
fi

#
# Run the strategy to do all of the work.
#
email_status "${BUILDCONFIG}" "Crochet build commenced"
run_strategy

# Clear the error exit handler
trap - INT QUIT KILL EXIT

# Clean up
disk_unmount_all

email_status "${BUILDCONFIG}" "Crochet build finished"
echo 'Finished at '`date`

