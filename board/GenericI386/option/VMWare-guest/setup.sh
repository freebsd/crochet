#
# Creates a suitable .vmdk description so the
# resulting image can be booted directly in VMWare.
#
# Good information about VMWare VMX files:
#   http://sanbarrow.com/vmx.html


#
# For a VMWare image, we want to put the disk image
# in a .vmwarevm directory which will also contain
# other generated files.  Massage the IMG variable
# accordingly and register the final VMWare machine
# setup with appropriate dir/file arguments.
#
vmware_config ( ) {
    IMGDIR=`dirname ${IMG}`
    IMGBASE=`basename ${IMG} | sed -e s/\.[^.]*$//`

    VMDIR=${IMGDIR}/${IMGBASE}.vmwarevm
    IMG=${VMDIR}/${IMGBASE}.img

    mkdir -p ${VMDIR}

    strategy_add $PHASE_FREEBSD_OPTION_INSTALL vmware_tweak_install
    strategy_add $PHASE_POST_UNMOUNT vmware_guest_build_vmdk ${VMDIR} ${IMGBASE} ${IMG}
}
strategy_add $PHASE_POST_CONFIG vmware_config

#
# After the GenericI386 board definition has installed
# world and kernel, we can adjust a few things
# to work better on VMWare.
#
vmware_tweak_install ( ) {
    # Add some stuff to etc/rc.conf
    echo 'ifconfig_em0="DHCP"' >> etc/rc.conf
    
    # TODO: Load VMWare-relevant modules in loader.conf?
}

# After unmounting the final image:
#  * pad it out to a full cylinder
#  * compute the geometry, and generate the VMDK file
#  * Build a template VMX file
#
# $1 = directory containing all VM files (including image)
# $2 = base name for generating VM files
# $3 = full path of image
#
vmware_guest_build_vmdk ( ) {
    # Compute the appropriate MBR geometry for this image
    CYLINDERS=$(( ($IMAGE_SIZE + 512 * 63 * 16 - 1) / 512 / 63 / 16 ))
    SECTORS=$(( $CYLINDERS * 16 * 63 ))

    # If the image isn't an exact multiple of the cylinder size, pad it.
    PADDED_SIZE=$(( $CYLINDERS * 512 * 16 * 63 ))
    if [ $PADDED_SIZE -gt $IMAGE_SIZE ]; then
	dd of=${IMG} if=/dev/zero bs=1 count=1 oseek=$(( $PADDED_SIZE - 1))
    fi

    # Write the VMDK disk description file.
    # This is almost straight from an example in the VMWare docs.
    VMDK_IMG_FILENAME=`basename $3`
    cat >$1/$2.vmdk <<EOF
# Disk DescriptorFile
version=1
CID=fffffffe
parentCID=ffffffff
createType="monolithicFlat"
# Extent description
RW ${SECTORS} FLAT "${VMDK_IMG_FILENAME}" 0
# The Disk Data Base
ddb.adapterType = "ide"
ddb.geometry.sectors = "63"
ddb.geometry.heads = "16"
ddb.geometry.cylinders = "${CYLINDERS}"
EOF

    # Write the VMX machine description file.
    cat >$1/$2.vmx <<EOF
config.version = "8"
displayName = "$2"
ethernet0.connectionType = "nat"
ethernet0.present= "true"
ethernet0.startConnected = "true"
ethernet0.virtualDev = "e1000"
floppy0.present = "FALSE"
guestOS = "freebsd"
ide0:0.filename = "$2.vmdk"
ide0:0.present = "TRUE"
memsize = "512"
uuid.action = "create"
virtualHW.version = "7"
EOF

}
