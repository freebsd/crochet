# Create a swap file and set it up correctly.
#
# Usage:
#   option SwapFile 768m
#
# Creates a 768m swap file as usr/swap0 and
# adds the correct configuration entries for
# it to be used as a swap file.
#
#  option SwapFile 768m
#  option SwapFile 768m file=/custom/filename
#  option SwapFile 768m deferred
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
    _SWAPFILE_DEFERRED=false
    _SWAPFILE_FILE=swapfile0
    _SWAPFILE_SIZE_MB=512
    S=`echo $1 | tr '[:upper:]' '[:lower:]'`
    N=`echo $S | tr -cd '[0-9]'`
    case $S in
        *.*)
            echo "SwapFile: Swapfile size cannot include a Decimal point"
            exit 2
            ;;
        *m|*mb|*mi|*mib)
	    _SWAPFILE_SIZE_MB=$N
            ;;
        *g|*gb|*gi|*gib)
	    _SWAPFILE_SIZE_MB=$(($N * 1024))
            ;;
        *)
            echo "SwapFile: Size argument $S not supported"
            exit 2
            ;;
    esac
    echo "SwapFile: Swapfile will be ${_SWAPFILE_SIZE_MB} MB"

    while shift; do
	case $1 in
	    file=*)
		_SWAPFILE_FILE=`echo $1 | sed -e 'sXfile=/*XX'`
		echo "SwapFile: swap file will be created in ${_SWAPFILE_FILE}"
		;;
	    deferred)
		echo "SwapFile: swap file will be created on first boot"
		_SWAPFILE_DEFERRED=true
		;;
	    *)
		if [ -n "$1" ]; then
		    echo "SwapFile: Unrecognized parameter '$1'"
		    exit 2
		fi
		;;
	esac
    done

    if $_SWAPFILE_DEFERRED; then
	mkdir -p usr/local/etc/rc.d
	_RCDIR=usr/local/etc/rc.d
	cp ${OPTIONDIR}/swapfile_create ${_RCDIR}/swapfile_create
	chmod 555 ${_RCDIR}/swapfile_create
	cat >>etc/rc.conf <<EOF
# On first boot, create a swap file
swapfile_create_enable="YES"
swapfile_create_file="/${_SWAPFILE_FILE}"
swapfile_create_size_mb="${_SWAPFILE_SIZE_MB}"
swapfile_create_free_mb=2048
EOF
	echo "SwapFile: installed rc.d/swapfile_create"
    else
	echo "SwapFile: sizing swap file to ${_SWAPFILE_SIZE_MB} MiB"
	truncate -s ${_SWAPFILE_SIZE_MB}M ${_SWAPFILE_FILE}
	chmod 0600 "${_SWAPFILE_FILE}"
	echo "md none swap sw,late,file=/${_SWAPFILE_FILE} 0 0" >> etc/fstab
	echo "SwapFile: swap file created and configured."
    fi
}

strategy_add $PHASE_FREEBSD_OPTION_INSTALL option_swapfile_install "$@"
