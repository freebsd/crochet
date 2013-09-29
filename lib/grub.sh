GRUB_INSTALL=/usr/local/sbin/grub-install

grub_check_install() {
 if [ -z `which grub-install` ]; then
        echo "GRUB2 not found"
        echo "Please install sysutils/grub2 and re-run this script."
        exit 1
    fi
}

grub_install_grub2 () {                                                         
    echo "Installing GRUB2 to /dev/${DISK_MD}"
    ${GRUB_INSTALL} /dev/${DISK_MD} || exit 1
}

