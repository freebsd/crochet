RPI_VC_SRC=${TOPDIR}/vchiq-freebsd

#
# Support for the VideoCore graphics driver for RaspberryPi.
#
# This is not needed for ordinary text usage of the RPi
# so it has been separated into an optional module.
# To enable it, add the following to your Crochet configuration:
#
#  option VideoCoreKernel
#
# To use it, you'll probably also want the userland libraries:
#
#  option VideoCoreUserland
#

videocore_src_check ( ) {
    if [ ! -d $RPI_VC_SRC ]; then
	echo "Need VideoCore kernel module code for FreeBSD"
	echo "Use the following command to fetch them:"
	echo
	echo " $ git clone git://github.com/gonzoua/vchiq-freebsd.git ${RPI_VC_SRC}"
	echo
	echo "Run this script again after you have the files."
	rm ${WORKDIR}/_.built-videocore-module
	exit 1
    fi
}
strategy_add $PHASE_CHECK videocore_src_check

videocore_build ( ) {
    if [ -f ${WORKDIR}/_.built-videocore-module ]
    then
	echo "Using VideoCore kernel module from previous build"
	return 0;
    fi

    echo "Building VideoCore kernel module at `date`"
    echo "    (Logging to ${WORKDIR}/_.videocore.build.log)"
    cd ${FREEBSD_SRC}
    buildenv=`make TARGET_ARCH=$TARGET_ARCH buildenvvars`
    cd ${RPI_VC_SRC}
    eval $buildenv SYSDIR=${FREEBSD_SRC}/sys MAKESYSPATH=${FREEBSD_SRC}/share/mk make >${WORKDIR}/_.videocore.build.log 2>&1 || exit 1

    touch ${WORKDIR}/_.built-videocore-module
}
strategy_add $PHASE_BUILD_OTHER videocore_build

# cwd: Target directory for install
videocore_install ( ) {
    echo "Installing VideoCore kernel module"
    DESTDIR=`pwd`
    cd ${FREEBSD_SRC}
    buildenv=`make TARGET_ARCH=$TARGET_ARCH buildenvvars`
    eval $buildenv SYSDIR=${FREEBSD_SRC}/sys MAKESYSPATH=${FREEBSD_SRC}/share/mk make -C ${RPI_VC_SRC} DESTDIR=$DESTDIR install || exit 1
}
strategy_add $PHASE_FREEBSD_BOARD_INSTALL videocore_install
