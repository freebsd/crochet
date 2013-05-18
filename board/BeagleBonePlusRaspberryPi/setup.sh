#
# *VERY* Experimental configuration to test ideas for a true "GENERIC"
# FreeBSD/arm kernel.
#
# This installs all the boot bits for both RaspberryPi and BeagleBone.
# The resulting image can load the kernel (with the appropriate
# board-specific FDT) on either platform.  We don't have a true
# working GENERIC kernel that can actually boot on either platform yet,
# but that's coming...
#

# This is mostly just a lot of juggling so that the RPi and BBone
# routines see the right BOARDDIR.

board_setup BeagleBone
board_setup RaspberryPi

KERNCONF=GENERIC

board_partition_image ( ) {
    disk_partition_mbr
    # Raspberry Pi boot loaders require FAT16, so this must be at least 17m
    disk_fat_create 20m 16
    disk_ufs_create
}
