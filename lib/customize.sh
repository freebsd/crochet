#
# Crochet defines a handful of standard shell functions
# to support end-user customization.  These are never
# used or overridden by board or option definitions.
#

# Run end-user customization late in the phase.
# Note that PHASE_BOOT_INSTALL gets cwd set to boot mountpoint automatically.

# COMMENTED OUT: On systems that don't use a boot partition, this
# breaks things.  I haven't figured out a really good workaround;
# people might just have to use strategy_add directly if they want to
# do any boot-partition customization.

#customize_boot_partition ( ) { }
#PRIORITY=200 strategy_add $PHASE_BOOT_INSTALL customize_boot_partition ${BOARD_BOOT_MOUNTPOINT}

# Copy overlay files early in the user customization phase.
# Typically, people want to copy static files and then
# tweak them afterwards.
customize_overlay_files ( ) {
    if [ -d ${WORKDIR}/overlay ]; then
	echo "Overlaying files from ${WORKDIR}/overlay"
	(cd ${WORKDIR}/overlay; find . | cpio -pmud ${BOARD_FREEBSD_MOUNTPOINT})
    fi
}
PRIORITY=50 strategy_add $PHASE_FREEBSD_USER_CUSTOMIZATION customize_overlay_files

# Run the shell hook late.  This means that functions
# explicitly registered by users calling strategy_add
# will run before this.
# Note that PHASE_FREEBSD_* gets cwd set to freebsd mountpoint automatically.
customize_freebsd_partition ( ) { }
PRIORITY=200 strategy_add $PHASE_FREEBSD_USER_CUSTOMIZATION customize_freebsd_partition ${BOARD_FREEBSD_MOUNTPOINT}

# Run end-user customization late in the phase.
customize_post_unmount ( ) { }
PRIORITY=200 strategy_add $PHASE_POST_UNMOUNT customize_post_unmount
