customize_boot_partition ( ) { }
customize_freebsd_partition ( ) { }
customize_post_unmount ( ) { }

customize_overlay_files ( ) {
    if [ -d ${WORKDIR}/overlay ]; then
	echo "Overlaying files from ${WORKDIR}/overlay"
	(cd ${WORKDIR}/overlay; find . | cpio -pmud ${BOARD_FREEBSD_MOUNTPOINT})
    fi
}
strategy_add $PHASE_FREEBSD_LATE_CUSTOMIZATION customize_overlay_files

