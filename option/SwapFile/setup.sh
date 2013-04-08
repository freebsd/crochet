

option_swapfile_install ( ) {
    echo "Creating $1 swap file"
    S=`echo $1 | tr '[:upper:]' '[:lower:]'`
    N=`echo $S | tr -cd '[0-9]'`
    case $S in
        *.*)
            echo "Swapfile size cannot include a Decimal point"
            exit 2
            ;;
        *m|*mb|*mi|*mib)
	    dd if=/dev/zero of="usr/swap0" bs=1024k count=$N
            ;;
        *g|*gb|*gi|*gib)
	    dd if=/dev/zero of="usr/swap0" bs=1024k count=$(($N * 1024))
            ;;
        *)
            echo "Size argument $1 not supported"
            exit 2
            ;;
    esac

    chmod 0600 "usr/swap0"
    echo 'swapfile="/usr/swap0"' >> etc/rc.conf
}

strategy_add $PHASE_FREEBSD_OPTION_INSTALL option_swapfile_install $1
