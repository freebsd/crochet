
================================================================

Chromebook
--------------------------------

This Crochet build was developed for the Samsung [Chromebook](http://www.samsung.com/ca/consumer/office/chrome-devices/chromebooks/XE303C12-A01CA).  

The FreeBSD-11 support for Chromebok Snow does not include MMC support.  Therefore the kernel attempts to boot from /dev/da0, a USB disk.  Crochet FreeBSD puts the root file system on the MMC card, in anticipation of the kernel being able to mount an MMC file system when it's supported.


Getting Started
--------------------------------

You will need to have entered developed mode and enabled boot from USB.  Instructions are [here](http://www.chromium.org/chromium-os/developer-information-for-chrome-os-devices/samsung-arm-chromebook)


Creating the Image
--------------------------------

You will need to know the exact size of the SDHC card you are using in order for Crochet to build the disk image. You will need to set the size, in bytes, of your SDHC card in `\board\Chromebook\setup.sh` 

For example
`
IMAGE_SIZE=8010072064
`

Setting Boot Paritions
--------------------------------

Once you have an image on an SDHC card, you will need to use the Chromium command line to set the bootable parition.  Insert the SDHC card and from the Chromium command line enter

`
sudo cgpt add -S 1 -T 5 -P 12 -i 1 /dev/mmcblk1
`

You can use cgpt to check that the parition table is set up correctly by typing

`sudo cgpt show /dev/mmcbkl1`

Reboot the Chromebook with

`sudo reboot`

Booting the Chromebook
--------------------------------

At the Chromium recovery screen type "CTRL-U" to boot the U-boot parition on the SDHC card.  You should see U-boot start on the Console.

To boot the kernel type:

<pre>
mmc dev 1
mmc rescan 1
fatload mmc 1:2 0x40f00000 kernel.bin
go 0x40f00000 
</pre>

You will see that the kernel will boot, and then fail to mount the root filesystem


