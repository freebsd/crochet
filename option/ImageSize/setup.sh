#
# A convenient way to set the image size:
#
# option ImageSize 900m
#
# is a synonym for
#
# IMAGE_SIZE=$((900 * MB))
#

compute_size ( ) {
    S=`echo $1 | tr '[:upper:]' '[:lower:]'`
    N=`echo $S | tr -cd '[0-9]'`
    case $S in
        *.*)    # Catch unsupported 1.5g case, since expr can't
                # cope with floats.
                echo "Decimal points are not supported in size arguments"
                exit 2
                ;;
        *m|*mb)
                IMAGE_SIZE=$(($N * 1000000))
                ;;
        *g|*gb)
                IMAGE_SIZE=$(($N * 1000000000))
                ;;
        *mi|*mib)
                IMAGE_SIZE=$(($N * 1024 * 1024))
                ;;
        *gi|*gib)
                IMAGE_SIZE=$(($N * 1024 * 1024 * 1024))
                ;;
        *)
                echo "Size argument $1 not supported"
                exit 2
                ;;
    esac
}

compute_size "$@"
