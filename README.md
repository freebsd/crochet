#Crochet-FreeBSD


Crochet is a tool for building bootable FreeBSD images.
This tool was formerly known as "freebsd-beaglebone" or
"beaglebsd" as the original work was done for BeagleBone.
But it now supports more boards and should easily extend
to support many more.

##FAQ


###How do I log in via ssh?


The default configuration of FreeBSD doesn't allow root to log in over ssh.  You have two options

* You can use [option User](https://github.com/freebsd/crochet/tree/master/option/User) in your Crochet configuration file to create a non-root user than can log in over ssh.

* If your platform has a serial console, log into the console using a serial cable and create yourself a user other than root.

###Why is nothing showing up on my HDMI or VGA monitor?

Not every platform supports HDMI or VGA yet.  Most platforms support RS-232.

###How do I install 3rd party applications?

Packages are available via the normal pkg repos:
```
pkg install nginx
```

You can also get a copy of the FreeBSD ports tree with the following commands (as root):
```
 portsnap fetch
 portsnap extract
```

You can browse the FreeBSD port collection at http://ftp.freebsd.org/pub/FreeBSD/ports/.

##Supported Platforms


* [Alix](http://pcengines.ch/alix.htm)
* [BananaPi](http://www.bananapi.org/)
* [BeagleBone](http://beagleboard.org/)
* [Chromebook Snow](http://www.samsung.com/ca/consumer/office/chrome-devices/chromebooks/XE303C12-A01CA)
* [Cubieboard](http://cubieboard.org/)
* [PandaBoard](http://pandaboard.org/)
* [RaspberryPi and RaspberryPi 2](http://www.raspberrypi.org/)
* [Soekris](http://soekris.com/)
* generic x86 systems.
* [Wandboard](http://wandboard.org/)
* [Versatile PB](http://arm.com/products/tools/development-boards/versatile/)
* [VMWare](http://www.vmware.com/)
* [ZedBoard](http://www.zedboard.org/)

##How to Build a Disk Image

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

2. CREATE a config file

   Start by copying config.sh.sample.

   The first line specifies the board configuration you
   want to use.  The name here should exactly match a
   directory under "board/".

   The configuration file can specify a wide variety of
   customizations for the generated image.  The config.sh.sample
   file includes extensive documentation in the form of
   comments.

3. RUN crochet.sh as root

   `$ sudo /bin/sh crochet.sh -c <config file>`

   The script will first check that you have any needed sources.
   If you don't, the script will tell you exactly how to obtain the
   missing pieces.  Follow the instructions and re-run the script
   until you have everything.

   As soon as it finds all the required pieces, the script will then
   compile everything and build the disk image.  This part of the
   process can take many hours.

   Crochet keeps the built system, kernel, and other files between runs.
   In many cases, you can adjust the configuration and re-run crochet
   to build a new image in just a few minutes.  However, if you
   update the FreeBSD sources or make a significant configuration
   change, you should probably delete the contents of the `work`
   directory to force everything to be rebuilt from scratch.

   Shortcut:  If you only want the most basic build for a board,
   you can use this command without creating a config file:

    `$ sudo /bin/sh crochet.sh -b <boardname>`

   However, if you want to tweak the build in any way, you will
   need to create a config file.

4. COPY the image to a suitable device (SD card, disk drive, etc)

   The script will suggest a 'dd' command to do this.

5. BOOT the image on your board.

   Again, read board/*board-name*/README for details.

##Command-line Options

* -b <board>: Load standard configuration for board
* -c <file>: Load configuration from file
* -e <email>: Email address to receive build status
* -u: Update source tree

##Potential Projects

There are still plenty of ways this script could
be improved:

* More boards.  Crochet should be able to support any board for
  which the FreeBSD source tree can build a working kernel.
  The hardest part is working out the various boot pieces required.
  Look at board/NewBoardExample for explanations for adding support
  for a new board.

* Out-of-tree kernel configuration.  Right now, these scripts assume
  kernel configuration files are in the FreeBSD source tree.  I don't
  think config(8) requires this; it would be nice to be able to
  include a tweaked kernel configuration as part of a board
  definition.

* Package Installation.  Pkgng packages can be installed using
    `option PackageInit <repository>` and
    `option Package <name>`
  assuming you have a suitable pkgng repository.  Cross-installs
  mostly work but there are subtle bugs that need to be tracked down.

  It should be possible to support pkg_add for same-architecture
  installs, though this requires tricky chroot games to get right.

* Swap.  The script should allow you to specify a swap size and
  automatically adjust the disk layout accordingly.  For now, we
  support creating swap files in the FreeBSD partition, which is easy
  and seems to work well enough.

* Support for read-only root and other more complex partitioning
  approaches.

* Improved VM building.  The VMWareGuest configuration can build
  a VMWare virtual machine (which is more than just the disk image).
  There are some bugs that might be problems with VMWareGuest
  setting up the various VM configuration files or might be FreeBSD
  kernel bugs; I'm not sure.  It should also be possible to directly
  build Bhyve, Parallels, VirtualBox, or OVF VM images.


