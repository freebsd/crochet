#
# Build a virtual machine that can be booted directly in VMWare.
#
# Usage:
#  option VMWare-guest [args]
#
# -n machine-name -- name of Virtual machine
# -p full-path-to-machine-dir  -- Full path of base dir
#      for new VM; e.g., /usr/vms/MyTestVm.vmwarevm
#

# Wait until after config is complete to register steps that
# require config variables such as ${IMG}.
#
vmware_guest_post_config ( ) {
    strategy_add $PHASE_FREEBSD_OPTION_INSTALL vmware_guest_tweak_install
    strategy_add $PHASE_POST_UNMOUNT vmware_guest_build_vm  ${IMG} "$@"
}
strategy_add $PHASE_POST_CONFIG vmware_guest_post_config "$@"

#
# After the GenericI386 board definition has installed
# world and kernel, we can adjust a few things
# to work better on VMWare.
#
vmware_guest_tweak_install ( ) {
    # Add some stuff to etc/rc.conf
    echo 'ifconfig_em0="DHCP"' >> etc/rc.conf
    
    # TODO: Load VMWare-relevant modules in loader.conf?
}

# Build the VMWare virtual machine directory:
#   FreeBSD-i386-GENERIC.vmwarevm/
#    +- VirtualMachine.vmx - Machine description
#    +- Disk0.vmdk - Disk description
#    +- Disk0.hdd - Disk image
#
# VMWare's Documentation for VMDK format:
# http://www.vmware.com/technical-resources/interfaces/vmdk.html
#
# A good resource for VMX parameter information:
# http://sanbarrow.com/vmx.html
#
# $1 = full path of image
# $@ = args passed to option
#
vmware_guest_build_vm ( ) {
    echo "Building VMWare VM"
    IMG=$1; shift

    args=`getopt n:p: $*`
    set -- $args
    while true; do
	case "$1" in
	    -n)
		IMGBASE="$2"
		shift; shift
		;;
	    -p)
		VMDIR="$2"
		shift; shift
		;;
	    --)
		shift; break
		;;
	esac
    done


    if [ -z "${IMGBASE}" ]; then
	IMGBASE=`basename ${IMG} | sed -e s/\.[^.]*$//`
    fi
    echo "  VMWare guest base name: $IMGBASE"
    if [ -z "${VMDIR}" ]; then
	VMDIR="${WORKDIR}/${IMGBASE}.vmwarevm"
    fi
    echo "  VMWare machine base directory:"
    echo "     $VMDIR"

    mkdir -p "${VMDIR}"
    rm -rf "${VMDIR}"/*
    strategy_add $PHASE_GOODBYE_LWW vmware_guest_goodbye "${VMDIR}"

    # Compute the appropriate MBR geometry for this image
    CYLINDERS=$(( ($IMAGE_SIZE + 512 * 63 * 16 - 1) / 512 / 63 / 16 ))
    SECTORS=$(( $CYLINDERS * 16 * 63 ))

    # If the image isn't an exact multiple of the cylinder size, pad it.
    PADDED_SIZE=$(( $CYLINDERS * 512 * 16 * 63 ))
    if [ $PADDED_SIZE -gt $IMAGE_SIZE ]; then
	dd of=${IMG} if=/dev/zero bs=1 count=1 oseek=$(( $PADDED_SIZE - 1))
    fi

    # Move the image into the VMWare VM directory
    # TODO: Should this copy instead of move?  Optionally copy?
    # TODO: Break the image into 2GB pieces and update the VMDK
    # descriptor appropriately.
    # TODO: Find or write a tool to convert the flat image
    # into a compressed sparse image, per VMWare docs:
    #
    # http://www.vmware.com/support/developer/vddk/vmdk_50_technote.pdf?src=vmdk
    #
    mv ${IMG} "${VMDIR}/Disk0.hdd"

    # Write the VMDK disk description file.
    # This is almost straight from an example in the VMWare docs.
    cid=`jot -r -w '%x' 1 0 4294967294`
    cat >"${VMDIR}/Disk0.vmdk" <<EOF
# Disk DescriptorFile
version=1
CID=${cid}
parentCID=ffffffff
createType="monolithicFlat"
# Extent description
RW ${SECTORS} FLAT "Disk0.hdd" 0
# The Disk Data Base
ddb.adapterType = "ide"
ddb.geometry.sectors = "63"
ddb.geometry.heads = "16"
ddb.geometry.cylinders = "${CYLINDERS}"
EOF

    # Write the VMX machine description file.
    # TODO: Should we provide options for some of
    # this?  Or is it enough for people to open
    # the VM in VMWare and adjust it themselves?
    cat >"${VMDIR}/VirtualMachine.vmx" <<EOF
config.version = "8"
virtualHW.version = "7"
displayName = "${IMGBASE}"
ethernet0.connectionType = "nat"
ethernet0.present= "true"
ethernet0.startConnected = "true"
ethernet0.virtualDev = "e1000"
floppy0.present = "FALSE"
guestOS = "freebsd"
ide0:0.filename = "Disk0.vmdk"
ide0:0.present = "TRUE"
memsize = "512"
tools.syncTime = "TRUE"
uuid.action = "create"
EOF
}

# Final instructions to user.
#
# $1 - Full path of final constructed VM.
# 
vmware_guest_goodbye ( ) {
    echo "Completed VMWare virtual machine is in:"
    echo "   $1"
}

