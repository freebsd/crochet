customize_boot_partition ( ) { }
customize_freebsd_partition ( ) { }
customize_post_unmount ( ) { }

customize_overlay_files ( ) {
    if [ -d ${WORKDIR}/overlay ]; then
	echo "Overlaying files from ${WORKDIR}/overlay"
	(cd ${WORKDIR}/overlay; find . | cpio -pmud ${BOARD_FREEBSD_MOUNTPOINT})
    fi
}
PRIORITY=50 strategy_add $PHASE_FREEBSD_USER_CUSTOMIZATION customize_overlay_files

PRIORITY=200 strategy_add $PHASE_FREEBSD_USER_CUSTOMIZATION customize_freebsd_partition ${BOARD_FREEBSD_MOUNTPOINT}

