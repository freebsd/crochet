#
# $1: firmware port name
# $2: firmware binary 
#
firmware_port_test ( ) {

    FIRMWARE_PATH="/usr/local/share/${1}"
    if [ ! -f "${FIRMWARE_PATH}/${2}" ]; then
        echo "Please install sysutils/$1 and re-run this script."
        echo "You can do this with:"
        echo "  $ sudo pkg install sysutils/$1"
        echo "or by building the port:"
        echo "  $ cd /usr/ports/sysutils/$1"
        echo "  $ make -DBATCH all install"
        exit 1
    fi
    echo "Found firmware port in:"
    echo "    ${FIRMWARE_PATH}"
}
