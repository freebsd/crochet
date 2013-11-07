TARGET_ARCH=i386
KERNCONF=GENERIC
IMAGE_SIZE=$((600 * 1000 * 1000))

#
# Builds a basic i386 image.
#

# Clean out any old i386 boot bits.
rm -rf ${WORKDIR}/boot
mkdir -p ${WORKDIR}/boot/defaults

#
# Note that the 'build' functions here all do a fake 'install' to
# ${WORKDIR}/boot so we can copy single files to the final image
# without having to hardcode deep paths into the FreeBSD source or
# object tree.
#

generic_i386_build_mbr ( ) {
    echo "Building MBR"
    cd ${FREEBSD_SRC}/sys/boot/i386/mbr
    make TARGET_ARCH=i386 > ${WORKDIR}/_.i386.mbr.log || exit 1
    make TARGET_ARCH=i386 DESTDIR=${WORKDIR} install || exit 1
}
strategy_add $PHASE_BUILD_OTHER generic_i386_build_mbr

generic_i386_build_boot2 ( ) {
    echo "Building Boot2"
    cd ${FREEBSD_SRC}/sys/boot/i386/boot2
    make TARGET_ARCH=i386 > ${WORKDIR}/_.i386.boot2.log || exit 1
    make TARGET_ARCH=i386 DESTDIR=${WORKDIR} install || exit 1
}
strategy_add $PHASE_BUILD_OTHER generic_i386_build_boot2

generic_i386_build_loader ( ) {
    echo "Building Loader"
    cd ${FREEBSD_SRC}/sys/boot/i386/loader
    make TARGET_ARCH=i386 > ${WORKDIR}/_.i386_loader.log || exit 1
    make TARGET_ARCH=i386 DESTDIR=${WORKDIR} NO_MAN=t install || exit 1
}
strategy_add $PHASE_BUILD_OTHER generic_i386_build_loader

# Even though there's only the default partition, we have
# to do extra work here to set all the boot bits.
# DISK_MD and DISK_UFS_PARTITION are set by the helper
# functions in lib/disk.sh.
generic_i386_partition_image ( ) {
    disk_partition_mbr
    disk_ufs_create
    echo "Installing bootblocks"
    gpart bootcode -b ${WORKDIR}/boot/mbr ${DISK_MD} || exit 1
    gpart set -a active -i 1 ${DISK_MD} || exit 1
    bsdlabel -B -b ${WORKDIR}/boot/boot ${DISK_UFS_PARTITION} || exit 1
}
strategy_add $PHASE_PARTITION_LWW generic_i386_partition_image

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
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_installkernel .

vmware_guest_post_config_names ( ) {
    if [ -z "${VMWARE_NAME}" ]; then
	VMWARE_NAME=`basename ${IMG} | sed -e s/\.[^.]*$//`
    fi
    if [ -z "${VMWARE_DIR}" ]; then
	VMWARE_DIR="${WORKDIR}/${VMWARE_NAME}.vmwarevm"
    fi
    mkdir ${VMWARE_DIR}
    IMG="${VMWARE_DIR}/Disk0.hdd"
    strategy_add $PHASE_POST_UNMOUNT vmware_guest_build_vm  ${IMG}
}
strategy_add $PHASE_POST_CONFIG vmware_guest_post_config_names

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

    # Avoid overwriting an existing VM
    BASEVMDIR="${VMWARE_DIR}"
    BASEVMNAME="${VMWARE_NAME}"
    i=1
    while [ -d "${VMWARE_DIR}" ]; do
	VMWARE_DIR="${BASEVMDIR}.${i}"
	VMWARE_NAME="${BASEVMNAME}.${i}"
    done

    echo "  VMWare machine name: $VMWARE_NAME"
    echo "  VMWare machine directory:"
    echo "     $VMWARE_DIR"
    mkdir -p "${VMWARE_DIR}"
    rm -rf "${VMWARE_DIR}"/*
    strategy_add $PHASE_GOODBYE_LWW vmware_guest_goodbye "${VMWARE_DIR}"

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
config.version = "8"
virtualHW.version = "10"
displayName = "${VMWARE_NAME}"
ethernet0.connectionType = "nat"
ethernet0.present= "true"
ethernet0.startConnected = "true"
ethernet0.virtualDev = "e1000"
guestOS = "freebsd"
ide0:0.filename = "Disk0.vmdk"
ide0:0.present = "TRUE"
memsize = "512"
tools.syncTime = "TRUE"
uuid.action = "create"
usb.present = "TRUE"
ehci.present = "TRUE"
ehci.pciSlotNumber = "0"
isolation.tools.dnd.disable = "TRUE"
isolation.tools.copy.disable = "TRUE"
isolation.tools.paste.disable = "TRUE"
floppy0.present = "FALSE"
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

