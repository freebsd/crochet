#
# Crochet defines a handful of standard shell functions
# to support end-user customization.  These are never
# defined or overridden by board or option definitions.
#

#customize_boot_partition ( ) { }
#customize_freebsd_partition ( ) { }
#customize_post_unmount ( ) { }

# If any of the above are actually defined, add them to the
# strategy.  We deliberately add them with a late priority.
#
install_customize_hooks ( ) {
    # If customize_boot_partition was defined, add it.
    if command -v customize_boot_partition >/dev/null 2>&1; then
        PRIORITY=200 strategy_add $PHASE_BOOT_INSTALL customize_boot_partition
    fi
    if command -v customize_freebsd_partition >/dev/null 2>&1; then
        PRIORITY=200 strategy_add $PHASE_FREEBSD_USER_CUSTOMIZATION customize_freebsd_partition
    fi
    if command -v customize_post_unmount >/dev/null 2>&1; then
        PRIORITY=200 strategy_add $PHASE_POST_UNMOUNT customize_post_unmount
    fi
}
strategy_add $PHASE_POST_CONFIG install_customize_hooks

# Copy overlay files early in the user customization phase.
# Typically, people want to copy static files and then
# tweak them afterwards.
customize_overlay_files ( ) {
    real_mountpoint=`realpath ${BOARD_FREEBSD_MOUNTPATH}`
    if [ -d ${TOPDIR}/overlay ]; then
        echo "Overlaying files from ${TOPDIR}/overlay"
        (cd ${TOPDIR}/overlay; pax -rw . ${real_mountpoint})
    fi
    if [ -d ${WORKDIR}/overlay ]; then
        echo "Overlaying files from ${WORKDIR}/overlay"
        (cd ${WORKDIR}/overlay; pax -rw . ${real_mountpoint})
    fi
}
PRIORITY=50 strategy_add $PHASE_FREEBSD_USER_CUSTOMIZATION customize_overlay_files
