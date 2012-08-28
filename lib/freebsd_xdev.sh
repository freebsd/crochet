freebsd_xdev_test ( ) (
    # We need the cross-tools for arm, if they're not already built.
    # This should work with arm.arm or arm.armv6 equally well.
    if [ -z `which arm-freebsd-cc` ]; then
	echo "Can't find FreeBSD xdev tools for ARM."
	echo "If you have FreeBSD-CURRENT sources in /usr/src, you can build these with the following command:"
	echo
	echo "cd /usr/src && sudo make xdev XDEV=arm XDEV_ARCH=arm"
	echo
	echo "Run this script again after you have the xdev tools installed."
	exit 1
    fi
    echo "Found FreeBSD xdev tools for ARM"
)
