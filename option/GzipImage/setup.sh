
#
# enable gzipping of images
#
GZIPIMAGE=$1

# compress the image, since it's easier to SCP around this way
gzip_image() {
    if [ -n "${GZIPIMAGE}" ]; then
        echo "Compressing image"
        if [ -f $IMG.gz ]; then 
           rm $IMG.gz
        fi
        gzip -k $IMG
    fi
}
strategy_add $PHASE_POST_UNMOUNT gzip_image

