#!/bin/sh

if [ -e rkflashtools/rkflashtool ]; then
	RKFLASHTOOL=rkflashtools/rkflashtool
else
	RKFLASHTOOL=../../rkflashtools/rkflashtool
fi
if [ ! -e $RKFLASHTOOL ]; then
	echo "Could not find rkflashtool."
	exit 1
fi
if [ -e rkutils/rkcrc ]; then
	RKCRC=rkutils/rkcrc
else
	RKCRC=../../rkutils/rkcrc
fi
if [ ! -e $RKCRC ]; then
	echo "Could not find rkcrc."
	exit 1
fi

echo "This script changes the KERNEL_IMG flash parameter of the Radxa Rock."
echo
echo "Please make sure the device is in recovery mode and then press enter."
read foo

PARAM_TXT=`mktemp`
PARAM_BIN=`mktemp`
$RKFLASHTOOL p | sed -e 's/0x60400000/0x60408000/' > $PARAM_TXT &&
$RKCRC -p $PARAM_TXT $PARAM_BIN &&
$RKFLASHTOOL w 0x0 0x2 < $PARAM_BIN 
rm -f $PARAM_TXT
rm -f $PARAM_BIN
