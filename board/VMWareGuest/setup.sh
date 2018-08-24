TARGET_ARCH=i386
KERNCONF=GENERIC-NODEBUG
IMAGE_SIZE=$((800 * 1000 * 1000))

. ${LIBDIR}/i386.sh

#
# Builds a basic i386 image.
#

# Value in MB.
VMWARE_MEMSIZE=1024

# Don't need custom mount since the default works for us.
generic_i386_board_install ( ) {
    # I386 images expect a copy of all the boot bits in /boot
    echo "Installing loader(8)"
    (cd ${WORKDIR} ; find boot | cpio -dump ${BOARD_FREEBSD_MOUNTPOINT})
    # Add some stuff to etc/rc.conf
    echo 'ifconfig_em0="DHCP"' >> etc/rc.conf
}
strategy_add $PHASE_FREEBSD_BOARD_INSTALL generic_i386_board_install

# Kernel installs in UFS partition
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .

vmware_guest_post_config_names ( ) {
    if [ -z "${VMWARE_NAME}" ]; then
	VMWARE_NAME=`basename ${IMG} | sed -e s/\.[^.]*$//`
    fi
    if [ -z "${VMWARE_DIR}" ]; then
	VMWARE_DIR="${WORKDIR}/${VMWARE_NAME}.vmwarevm"
    fi

    # Avoid overwriting an existing VM
    # TODO: use *-${i}.vmwarevm instead of *.vmwarevm.${i}
    # the latter confuses Mac OS extension-based file open logic.
    BASEVMDIR=`echo ${VMWARE_DIR} | sed -e s/.vmwarevm$//`
    BASEVMNAME="${VMWARE_NAME}"
    i=1
    while [ -d "${VMWARE_DIR}" ]; do
	VMWARE_DIR="${BASEVMDIR}-${i}.vmwarevm"
	VMWARE_NAME="${BASEVMNAME}.${i}"
	i=$(($i + 1))
    done

    mkdir ${VMWARE_DIR}
    IMG="${VMWARE_DIR}/Disk0.hdd"
    strategy_add $PHASE_POST_UNMOUNT vmware_guest_build_vm  ${IMG}
}
PRIORITY=200 strategy_add $PHASE_POST_CONFIG vmware_guest_post_config_names

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
#
vmware_guest_build_vm ( ) {
    echo "Building VMWare VM"
    IMG=$1; shift

    echo "  VMWare machine name: $VMWARE_NAME"
    echo "  VMWare machine directory:"
    echo "     $VMWARE_DIR"

    strategy_add $PHASE_GOODBYE_LWW vmware_guest_goodbye "${VMWARE_DIR}"

    # Compute the appropriate MBR geometry for this image
    CYLINDERS=$(( ($IMAGE_SIZE + 512 * 63 * 16 - 1) / 512 / 63 / 16 ))
    SECTORS=$(( $CYLINDERS * 16 * 63 ))

    # If the image isn't an exact multiple of the cylinder size, pad it.
    PADDED_SIZE=$(( $CYLINDERS * 512 * 16 * 63 ))
    if [ $PADDED_SIZE -gt $IMAGE_SIZE ]; then
	echo dd of=${IMG} if=/dev/zero bs=1 count=1 oseek=$(( $PADDED_SIZE - 1))
	dd of=${IMG} if=/dev/zero bs=1 count=1 oseek=$(( $PADDED_SIZE - 1))
    fi

    # Write the VMDK disk description file.
    # This is almost straight from an example in the VMWare docs.
    cid=`jot -r -w '%x' 1 0 4294967294`
    cat >"${VMWARE_DIR}/Disk0.vmdk" <<EOF
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
    cat >"${VMWARE_DIR}/VirtualMachine.vmx" <<EOF
.encoding = "UTF-8"
config.version = "8"
virtualHW.version = "9"
displayName = "${VMWARE_NAME}"
ethernet0.connectionType = "nat"
ethernet0.present= "true"
ethernet0.startConnected = "true"
ethernet0.virtualDev = "e1000"
guestOS = "freebsd"
ide0:0.filename = "Disk0.vmdk"
ide0:0.present = "TRUE"
memsize = "${VMWARE_MEMSIZE}"
tools.syncTime = "TRUE"
uuid.action = "create"
usb.present = "TRUE"
ehci.present = "TRUE"
ehci.pciSlotNumber = "0"
isolation.tools.dnd.disable = "TRUE"
isolation.tools.copy.disable = "TRUE"
isolation.tools.paste.disable = "TRUE"
virtualHW.productCompatibility = "hosted"
floppy0.present = "FALSE"
ethernet0.addressType = "generated"
ethernet0.pciSlotNumber = "-1"
usb.pciSlotNumber = "-1"
replay.supported = "FALSE"
replay.filename = ""
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

