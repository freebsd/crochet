
#
# Compress the final image
#
compress_image() {
    echo "Compressing image"
    case $1 in
        gzip)
            if [ -f $IMG.gz ]; then
                rm $IMG.gz
            fi
            gzip -k $IMG
            ;;
        *)
            if [ -f $IMG.xz ]; then
                rm $IMG.xz
            fi
            xz -k $IMG
            ;;
    esac
}
strategy_add $PHASE_POST_UNMOUNT compress_image $1

