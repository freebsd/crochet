
# set the variable $OS_VERSION
os_determine_os_version ( ) {
    OS_VERSION=`/usr/bin/grep "REVISION=" ${FREEBSD_SRC}/sys/conf/newvers.sh | awk 'BEGIN {FS="="} {print $2}' | /usr/bin/tr -d '"'`
    MAJOR_OS_VERSION=`echo $OS_VERSION | awk 'BEGIN {FS="."} {print $1}'`
#    echo "OS version is: $OS_VERSION"; 
    echo "OS major version is: $MAJOR_OS_VERSION";
}

# find the OBJS
os_determine_obj_location ( ) {
    if [ "$MAJOR_OS_VERSION" -eq "8" ]
    then
        OBJFILES=${MAKEOBJDIRPREFIX}/i386${FREEBSD_SRC}/
    fi
    if [ "$MAJOR_OS_VERSION" -eq "9" ]
    then
        OBJFILES=${MAKEOBJDIRPREFIX}/i386.i386${FREEBSD_SRC}/
    fi
    if [ "$MAJOR_OS_VERSION" -eq "10" ]
    then
        OBJFILES=${MAKEOBJDIRPREFIX}/i386.i386${FREEBSD_SRC}/
    fi
    echo "Object files are at: "${OBJFILES}
}

os_setup_os_variables ( ) {
    os_determine_os_version
    os_determine_obj_location
}

strategy_add $PHASE_POST_CONFIG os_setup_os_variables


