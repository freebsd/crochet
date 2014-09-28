TARGET_ARCH=i386
KERNCONF=SOEKRIS
IMAGE_SIZE=$((1024 * 1000 * 1000))

. ${LIBDIR}/i386.sh

# copy the build config
soekris_copy_buildconfig ( ) {
    KERNEL_CONFIG_FILE="SOEKRIS"
    echo "Copying build config ${KERNEL_CONFIG_FILE} to source tree"
    cp ${BOARDDIR}/conf/${KERNEL_CONFIG_FILE} ${FREEBSD_SRC}/sys/i386/conf/${KERNCONF}
}
strategy_add $PHASE_POST_CONFIG soekris_copy_buildconfig

# Kernel installs in UFS partition
strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
