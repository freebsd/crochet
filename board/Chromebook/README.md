
================================================================

Chromebook
--------------------------------

This Crochet build was developed for the Samsung [Chromebook](http://www.samsung.com/ca/consumer/office/chrome-devices/chromebooks/XE303C12-A01CA).  


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

At the Chromium recovery screen type "CTRL-U" to boot the U-boot parition on the SDHC card.  You should see U-boot start on the Console.


 





