GRUB_INSTALL=/usr/local/sbin/grub-install

grub_install_grub2 () {                                                         
    echo "Installing GRUB2"                                                              
    /usr/local/sbin/grub-install ${DISK_MD} || exit 1                                    
}

