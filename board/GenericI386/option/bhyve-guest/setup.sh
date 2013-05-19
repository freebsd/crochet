#
# Add necessary bits for the image to run as a guest under bhyve.
#

bhyve_loader_conf ( ) {
    # Remove console=comconsole
    sed -i "" 's/console=comconsole/#console=comconsole/g' boot/loader.conf

    # Load virtio modules
    cat >> boot/loader.conf <<EOF
# Added for bhyve use:
virtio_load="YES"
virtio_pci_load="YES"
virtio_blk_load="YES"
if_vtnet_load="YES"
hw.pci.honor_msi_blacklist=0
#smbios.bios.vendor="Bochs"
smbios.bios.vendor="BHYVE"

EOF
}
strategy_add $PHASE_FREEBSD_OPTION_INSTALL bhyve_loader_conf

bhyve_etc_ttys ( ) {
    cat >> etc/ttys <<EOF
console "/usr/libexec/getty std.9600"   vt100   on   secure
EOF
}
strategy_add $PHASE_FREEBSD_OPTION_INSTALL bhyve_etc_ttys

bhyve_helper_scripts ( ) {
    cp ${OPTIONDIR}/bhyve-*.sh ${WORKDIR}
    # TODO: Customize the scripts
}
strategy_add $PHASE_FREEBSD_OPTION_INSTALL bhyve_helper_scripts
