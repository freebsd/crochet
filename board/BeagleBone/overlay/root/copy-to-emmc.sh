#
# Shell script to copy FreeBSD system from SDCard to eMMC
#
# Warning:  This erases the eMMC before copying!
#

echo 'Warning: This script erases /dev/mmcsd1'
echo 'It then copies your FreeBSD system from /dev/mmcsd0'
echo
echo 'If you booted from SD:'
echo '   /dev/mmcsd1 will refer to the eMMC'
echo '   /dev/mmcsd0 will refer to the micro-SD card'
echo
echo 'If you booted from eMMC, it's the other way around'
echo
echo 'If you are certain you want this script to erase stuff,'
echo 'edit the script, remove the "exit 1" command, and run it again.'


# Remove this line to make this script actually do something.
exit 1


# Erase /dev/mmcsd1!  (Hope you meant this!)
dd if=/dev/zero of=/dev/mmcsd1 bs=64k count=1

# Create a 40m MSDOS partition, copy boot files over
gpart create -s mbr mmcsd1
gpart add -t fat32 -s 40m mmcsd1
newfs_msdos -L 'EMMCBOOT' -F 32 /dev/mmcsd1s1
mount_msdosfs /dev/mmcsd1s1 /mnt
cp /boot/msdos/* /mnt
umount /mnt

# Format the rest as a standard FreeBSD partition
gpart add -t freebsd mmcsd1
bsdlabel -w mmcsd1s2
newfs /dev/mmcsd1s2a
tunefs -N enable -j enable -t enable -L 'eMMCroot' /dev/mmcsd1s2a
mount /dev/mmcsd1s2a /mnt

# Copy the system over (but skip a few things)
tar -c -f - -C / \
	--exclude usr/src \
	--exclude usr/ports \
	--exclude usr/obj \
	--exclude mnt \
	. \
| tar -x -f - -C /mnt

# Overwrite fstab
cat <<EOF >>/mnt/etc/fstab
/dev/msdosfs/EMMCBOOT /boot/msdos msdosfs rw,noatime 0 0
/dev/ufs/eMMCroot / ufs rw,noatime 1 1
md /tmp mfs rw,noatime,-s30m 0 0
md /var/log mfs rw,noatime,-s15m 0 0
md /var/tmp mfs rw,noatime,-s5m 0 0
EOF

