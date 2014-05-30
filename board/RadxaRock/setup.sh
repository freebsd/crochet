KERNCONF=RADXA
KERNIMG=${WORKDIR}/kernel.img
RADXA_RKUTILS_SRC=${TOPDIR}/rkutils
RADXA_RKFLASHTOOLS_SRC=${TOPDIR}/rkflashtools
IMAGE_SIZE=$((1000 * 1000 * 1000))
TARGET_ARCH=armv6

radxa_check_rkutils ( ) {
	if [ -d ${RADXA_RKUTILS_SRC} ]; then
		echo "rkutils sources in:"
		echo "    ${RADXA_RKUTILS_SRC}"
	else
		echo
		echo "Expected to see rkutils sources in:"
		echo "    ${RADXA_RKUTILS_SRC}"
		echo
		echo "Use the following command to get the rkutils sources:"
		echo "    git clone https://github.com/naobsd/rkutils.git"
		exit 1
	fi
}
strategy_add $PHASE_CHECK radxa_check_rkutils

radxa_build_rkcrc ( ) {
	if [ -f $1/_.rkcrc.built ]; then
		echo "Using rkcrc from previous build."
		return 0
	fi
	cd "$1"
	echo "Building rkcrc at " `date`
	if make rkcrc> $1/_.rkcrc.build.log 2>&1; then 
		# success
	else
		echo "  Failed to build rkcrc."
		echo "  Log in $1/_.rkcrc.build.log"
		exit 1
	fi
	touch $1/_.rkcrc.built
}
strategy_add $PHASE_BUILD_OTHER radxa_build_rkcrc ${RADXA_RKUTILS_SRC}

radxa_create_kernel_image ( ) {
	echo "Creating kernel image at: ${KERNIMG}"
	$1/rkcrc -k ${FREEBSD_OBJDIR}/sys/RADXA/kernel.bin ${KERNIMG}
}
strategy_add $PHASE_BUILD_OTHER radxa_create_kernel_image ${RADXA_RKUTILS_SRC}

radxa_check_rkflashtools ( ) {
	if [ -d ${RADXA_RKFLASHTOOLS_SRC} ]; then
		echo "rkflashtools sources in:"
		echo "    ${RADXA_RKFLASHTOOLS_SRC}"
	else
		echo
		echo "Expected to see rkflashtools sources in:"
		echo "    ${RADXA_RKFLASHTOOLS_SRC}"
		echo
		echo "Use the following command to get the rkflashtools" \
			"sources:"
		echo "    git clone" \
			"https://github.com/crewrktablets/rkflashtools.git"
		exit 1
	fi

}
strategy_add $PHASE_CHECK radxa_check_rkflashtools

radxa_build_rkflashtool ( ) {
	if [ -f $1/_.rkflashtool.built ]; then
		echo "Using rkflashtool from previous build."
		return 0
	fi
	cd "$1"
	sed -e 's/gcc/cc/' -i .bak Makefile
	echo "Building rkflashtool at " `date`
	if make > $1/_.rkflashtool.build.log 2>&1; then 
		# success
	else
		echo "  Failed to build rkflashtool"
		echo "  Log in $1/_.rkflashtool.build.log"
		exit 1
	fi
	touch $1/_.rkflashtool.built
}
strategy_add $PHASE_BUILD_OTHER radxa_build_rkflashtool ${RADXA_RKFLASHTOOLS_SRC}

strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .

radxa_goodbye ( ) {
	board_default_goodbye
	echo "The kernel must be installed in the NAND of the Radxa Rock."
	echo
	echo "Follow these steps to put the device in recovery mode:"
	echo "1) Power off your Radxa Rock"
	echo "2) Hold the Recovery button"
	echo "3) Connect USB OTG port to your computer"
	echo "4) Hold the Recovery button for 5 seconds"
	echo
	echo "Before we boot FreeBSD for the first time, we need to change"
	echo "the KERNEL_IMG parameter.  This only needs to happen once."
	echo "Run the following script after the board is in recovery mode:"
	echo "   ${BOARDDIR}/change-param.sh"
	echo 
	echo "To install the kernel in the NAND:"
	echo "  ${RADXA_RKFLASHTOOLS_SRC}/rkflashtool w 0x4000 0x5000 \\"
	echo "      < ${KERNIMG}"
	echo
	echo "To boot:"
	echo "1) Disconnect the USB cable from the OTG port"
	echo "2) Connect the USB flash drive"
	echo "3) Turn the Radxa Rock on"
	echo
}
strategy_add $PHASE_GOODBYE_LWW radxa_goodbye
