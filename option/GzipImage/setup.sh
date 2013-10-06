
#
# Gzip the final image
#
gzip_image() {
    echo "Compressing image"
    if [ -f $IMG.gz ]; then
       rm $IMG.gz
    fi
    gzip -k $IMG
}
strategy_add $PHASE_POST_UNMOUNT gzip_image

