
mkimage_check ( ) {
    if python --version; then
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

# $1: input boot file
# $2: output
mkimage ( ) (
    cd ${BOARDDIR}/mkimage
    python imagetool-uncompressed.py $1 $2
)
