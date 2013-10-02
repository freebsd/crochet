
# set the variable $OS_VERSION
determine_os_version ( ) {
    OS_VERSION=`/usr/bin/grep "REVISION=" ${FREEBSD_SRC}/sys/conf/newvers.sh | awk 'BEGIN {FS="="} {print $2}' | /usr/bin/tr -d '"'`
    MAJOR_OS_VERSION=`echo $OS_VERSION | awk 'BEGIN {FS="."} {print $1}'`
#    echo "OS version is: $OS_VERSION"; 
    echo "OS major version is: $MAJOR_OS_VERSION";
}

strategy_add $PHASE_POST_CONFIG determine_os_version




