Crochet is a tool for building bootable FreeBSD images.

It can currently build images for:
* [Alix](http://pcengines.ch/alix.htm)
* [BeagleBone](http://beagleboard.org/)
* [PandaBoard](http://pandaboard.org/)
* [RaspberryPi](http://www.raspberrypi.org/)
* [Soekris](http://soekris.com/)
* generic x86 systems.
* [Wandboard](http://wandboard.org/)
* [VMWare](http://www.vmware.com/)
* [ZedBoard](http://www.zedboard.org/)

This tool was formerly known as "freebsd-beaglebone" or
"beaglebsd" as the original work was done for BeagleBone.
But it now supports more boards and should easily extend
to support many more.

***********************************************************

How to Build a Disk Image
-------------------------

The crochet.sh script can build a complete bootable
FreeBSD image ready to be copied to a suitable device
(e.g., SDHC card, Compact Flash card, disk drive, etc.).
The script runs on FreeBSD-CURRENT, though some people
have reported success running it on FreeBSD 9-STABLE.

Using the script to build an image consists of a few steps:

1. READ board/*board-name*/README

   The board-specific directories each have a README
   with various details about running FreeBSD on a particular
   system.  (Some boards have several README files in
   subdirectories with additional technical information.)

   If you are looking at this on the Github web
   interface, click "board" above to see more about
   the boards that are currently supported.

2. CREATE a config file

   Start by copying config.sh.sample.

   The first line specifies the board configuration you
   want to use.  The name here should exactly match a
   directory under "board/".

3. RUN crochet.sh as root

   `$ sudo /bin/sh crochet.sh -c <config file>`

   The script will first check that you have any needed sources.
   If you don't, the script will tell you exactly how to obtain the
   missing pieces.  Follow the instructions and re-run the script
   until you have everything.

   As soon as it finds all the required pieces, the script will then
   compile everything and build the disk image.  This part of the
   process can take several hours.

   Shortcut:  If you only want the most basic build for a board,
   you can use this command without creating a config file:
    `$ sudo /bin/sh crochet.sh -b <boardname>`
   However, if you want to tweak the build in any way, you will
   need to create a config file.

4. COPY the image to a suitable device (SD card, disk drive, etc)

   The script will suggest a 'dd' command to do this.

5. BOOT the image on your board.

   Again, read board/*board-name*/README for details.

***********************************************************

COMMAND-LINE OPTIONS
------------

* -b <board>: Load standard configuration for board
* -c <file>: Load configuration from file
* -e <email>: Email address to receive build status
* -u: Update source tree

***********************************************************

PROJECTS
------------

The list of potential projects is [here](https://github.com/kientzle/crochet-freebsd/wiki/Projects)
