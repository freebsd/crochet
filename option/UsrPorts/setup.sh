#
# option UsrPorts
#
# Use portsnap to fetch an up-to-date ports tree and install
# it on the image
#
# option UsrPorts /path/to/usr/ports
#
# Copy an existing ports tree from the indicated path.

option_usrports_portsnap ( ) {
    mkdir -p $1/usr/ports
    echo "Updating ports snapshot at "`date`
    portsnap fetch > ${WORKDIR}/_.portsnap.fetch.log
    echo "Installing ports tree at "`date`
    portsnap -p $1/usr/ports extract > ${WORKDIR}/_.portsnap.extract.log
}

# $1 - image root
# $2 - directory to copy ports from
option_usrports_copydir ( ) {
    mkdir -p $1/usr/ports
    echo "Copying ports tree at "`date`
    echo "    To:   $1/usr/ports"
    echo "    From: $2"
    if [ -d "$2/.svn" ]; then
	# Idea: Use SVN export to get just the good stuff
	# Maybe:  Just do this if $2 looks like a URL?
    else
	# Use find/cpio to copy it
	#
	# * Copy distfiles dir but not the contents
	# * Omit any 'work' directories
	# * Omit the .svn dir
	#
	cd $2 ;
	find .		\
	    -not \( -type d -name work -prune \)	\
	    -not \( -path ./.svn -prune \)		\
	    -not \( -path ./distfiles -prune \)		\
	    -o -name distfiles				\
	    | cpio -pdmu $1/usr/ports
    fi
}

if [ -z "$1" ]; then
    # Plain "option UsrPorts" with no argument
    strategy_add $PHASE_FREEBSD_OPTION_INSTALL option_usrports_portsnap '${BOARD_FREEBSD_MOUNTPOINT}'
else
    # "option UsrPorts arg"
    strategy_add $PHASE_FREEBSD_OPTION_INSTALL option_usrports_copydir '${BOARD_FREEBSD_MOUNTPOINT}' "$1"
fi
