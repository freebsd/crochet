#!/bin/sh
#
# Shell script to copy FreeBSD system from SDCard to eMMC
#
# Warning:  This erases the eMMC before copying!
#

echo 'Warning: This script erases /dev/mmcsd1'
echo 'It then copies your FreeBSD system from /dev/mmcsd0'
echo
echo 'If you booted from SD:'
echo '   /dev/mmcsd0 will refer to the micro-SD card'
echo '   /dev/mmcsd1 will refer to the eMMC'
echo
echo 'If you booted from eMMC, it will be the other way around'
echo '(Check the boot messages to verify your situation.)'
echo
echo 'If you are certain you want this script to erase stuff,'
echo 'edit the script, remove the "exit 1" command, and run it again.'


# Remove the following line to make this script actually do something.
exit 1

echo
echo 'Erasing /dev/mmcsd1!  (Hope you meant this!)'
dd if=/dev/zero of=/dev/mmcsd1 bs=64k count=1

echo
echo 'Creating MSDOS FAT16 boot partition on eMMC'
gpart create -s mbr mmcsd1
gpart add -s 16m -t '!14' mmcsd1
gpart set -a active -i 1 mmcsd1
newfs_msdos -L 'EMMCBOOT' -F 16 /dev/mmcsd1s1

echo
echo 'Copying boot files to eMMC boot partition'
mount_msdosfs /dev/mmcsd1s1 /mnt
cp /boot/msdos/* /mnt
echo 'loaderdev=disk1' >>/mnt/bb-uenv.txt
sync
umount /mnt

echo
echo 'Creating FreeBSD partition on eMMC'
gpart add -t freebsd mmcsd1
gpart create -s BSD mmcsd1s2
gpart add -t freebsd-ufs -a 32k mmcsd1s2
newfs /dev/mmcsd1s2a
tunefs -N enable -j enable -t enable -L 'eMMCroot' /dev/mmcsd1s2a
mount /dev/mmcsd1s2a /mnt

echo
echo 'Copying the system from SD to eMMC'

tar -c -f - -C / \
	--exclude usr/src \
	--exclude usr/ports \
	--exclude usr/obj \
	--exclude 'usr/swap*' \
	--exclude mnt \
	--exclude .sujournal \
	--exclude var/run \
	--exclude dev \
	. \
| tar -x -f - -C /mnt

echo
echo 'Cleaning up the copied system'
# Reset permissions, ensure the required directories
(cd /mnt ; mtree -Uief /etc/mtree/BSD.root.dist)
(cd /mnt/usr ; mtree -Uief /etc/mtree/BSD.usr.dist)
(cd /mnt/usr/include ; mtree -Uief /etc/mtree/BSD.include.dist)
(cd /mnt/var ; mtree -Uief /etc/mtree/BSD.var.dist)
# Have the copied system generate its own keys
# (In particular, if this SD card is used to copy
# a system onto a bunch of BBBlacks, we do not want
# them to all have the same SSH keys.)
rm -f /mnt/etc/ssh/*key*

echo
echo 'Replacing fstab on eMMC'
cat <<EOF >/mnt/etc/fstab
/dev/msdosfs/EMMCBOOT /boot/msdos msdosfs rw,noatime       0 0
/dev/ufs/eMMCroot     /           ufs     rw,noatime       1 1
#md                    /tmp        mfs     rw,noatime,-s30m 0 0
md                    /var/log    mfs     rw,noatime,-s15m 0 0
md                    /var/tmp    mfs     rw,noatime,-s5m  0 0
EOF
echo
cat /mnt/etc/fstab
echo

sync; sync; sync

echo
echo 'System copied.'
echo
echo 'eMMC root filesystem is still mounted on /mnt'
echo 'You can make changes there now before rebooting if you wish.'
echo
echo 'To reboot from eMMC:'
echo '  * Clean shutdown: shutdown -p now'
echo '  * Remove power'
echo '  * Remove SD card'
echo '  * Reapply power (do NOT hold boot switch)'


