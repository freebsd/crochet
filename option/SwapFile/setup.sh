#
# Create a swap file and set it up correctly.
#
# Usage:
#   option AddSwap 768m
#
# Creates a 768m swap file as usr/swap0 and
# adds the correct configuration entries for
# it to be used as a swap file.
#
#
# TODO: expand the command line options here so that
# the following all work:
#
#  option AddSwap 768m
#  option AddSwap 768m file=/custom/filename
#  option AddSwap 768m deferred
#
# The last would causes the swap file to actually get created
# on first boot.  (By adding a start script to /usr/local/etc/rc.d
# and enabling it with a suitable option.)  In particular,
# this would work well with AutoSize, allowing you to create
# images that can be copied onto any media:  If the media is
# larger than the image, the image resizes and creates swap
# at that time.
#
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
    echo 'md none swap sw,file=/usr/swap0 0 0' >> etc/fstab
}

strategy_add $PHASE_FREEBSD_OPTION_INSTALL option_swapfile_install $1
