GRUB_INSTALL=/usr/local/sbin/grub-install
GRUB_MKCONFIG=/usr/local/sbin/grub-mkconfig

grub_check_install() {
 if [ -z `which grub-install` ]; then
        echo "GRUB2 not found"
        echo "Please install sysutils/grub2 and re-run this script."
        exit 1
    fi
}

grub_install_grub2 () {                                                         
    echo "Installing GRUB2 to /dev/${DISK_MD} and GRUB files to ${BOARD_FREEBSD_MOUNTPOINT}/boot"
    ${GRUB_INSTALL} --boot-directory=${BOARD_FREEBSD_MOUNTPOINT}/boot /dev/${DISK_MD} || exit 1
}

# configure grub
grub_configure_grub ( ) {
    echo "Creating GRUB2 Configuration to ${BOARD_FREEBSD_MOUNTPOINT}/boot/grub/grub.cfg"
    mkdir ${BOARD_FREEBSD_MOUNTPOINT}/boot/grub/   
    ${GRUB_MKCONFIG} -o ${WORKDIR}/grub.cfg
    cp ${WORKDIR}/grub.cfg.new ${BOARD_FREEBSD_MOUNTPOINT}/boot/grub/
}



