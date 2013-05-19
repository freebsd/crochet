#!/bin/sh
echo ""
echo "Loading the vmm, if_tap, bridgestp and if_bridge kernel modules"
echo ""

kldload vmm
kldload if_tap
kldload bridgestp
kldload if_bridge

echo ""
echo "Creating te bridge0 network interface"
echo ""
ifconfig bridge0 create

echo ""
echo "Running kldstat"
echo ""
kldstat
