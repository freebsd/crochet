#
# A utility used by the Raspberry Pi build.
#

mkimage_python_check ( ) {
    if python --version >/dev/null 2>&1; then
        true
    else
        echo "Need Python to run RaspberryPi mkimage tool"
        echo
        echo "Install Python from port or package."
        echo
        echo "Run this script again after you have the files."
        exit 1
    fi
}

strategy_add $PHASE_CHECK mkimage_python_check


# $1: input boot file
# $2: output
mkimage ( ) {
    (
        cd ${BOARDDIR}/mkimage
        python imagetool-uncompressed.py $1 -
    ) > $2
}
