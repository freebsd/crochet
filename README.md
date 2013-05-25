Crochet is a tool for building bootable FreeBSD images.

It can currently build images for:
* BeagleBone
* RaspberryPi
* PandaBoard
* ZedBoard
* generic x86 systems.
* VMWare

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

   $ sudo /bin/sh crochet.sh -c <config file>

   The script will first check that you have any needed sources.
   If you don't, the script will tell you exactly how to obtain the
   missing pieces.  Follow the instructions and re-run the script
   until you have everything.

   As soon as it finds all the required pieces, the script will then
   compile everything and build the disk image.  This part of the
   process can take several hours.

   Shortcut:  If you only want the most basic build for a board,
   you can use this command without creating a config file:
    $ sudo /bin/sh crochet.sh -b <boardname>
   However, if you want to tweak the build in any way, you will
   need to create a config file.

4. COPY the image to a suitable device (SD card, disk drive, etc)

   The script will suggest a 'dd' command to do this.

5. BOOT the image on your board.

   Again, read board/*board-name*/README for details.

***********************************************************

PROJECTS
------------

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
    option PackageInit <repository>
    option Package <name>
  assuming you have a suitable pkgng repository.  Cross-installs
  mostly work; there are a few minor bugs in the pkgng tools that
  are being actively worked on.

  It should be possible to support pkg_add for same-architecture
  installs, though this requires tricky chroot games to get right.

* Swap.  The script should allow you to specify a swap size and
  automatically adjust the disk layout accordingly.  For now, we
  support creating swap files in the FreeBSD partition, which is easy
  and seems to work well enough.

* Support for read-only root and other more complex partitioning
  approaches.

* NanoBSD-style split-partition support.  Ideally, this would be a
  "mix in" capability that users could request with any board.

* Improved support for virtual environments.  The VMWare-guest option
  demonstrates how to do this.  It should be relatively
  straightforward to add support for directly building Parallels,
  VirtualBox, or standard OVF VM images.
