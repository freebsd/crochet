Crochet builds bootable FreeBSD images for a number of popular boards.

It was formerly known as "freebsd-beaglebone" or "beaglebsd"
as the original work was done for BeagleBone.  But it now supports
more boards and should easily extend to support many more
(including non-ARM systems).

***********************************************************

How to Build a Disk Image
-------------------------

The crochet.sh script can build a complete bootable FreeBSD
image ready to be copied to a suitable device (e.g., MicroSDHC card,
Compact Flash card, disk drive, etc.).  The script runs on
FreeBSD-CURRENT (March 2012 or later), though some people have
had success running it on FreeBSD 9-STABLE.

Using the script to build an image consists of a few steps:

1. READ board/<board-name>/README

   The board-specific directories each have a README
   with various details about running FreeBSD on a particular
   system.  (Some boards have several README files in
   subdirectories with additional technical information.)

2. EDIT config.sh

   Start by copying config.sh.sample.

   The first line specifies the board configuration you
   want to use.  The name here should exactly match a
   directory under "board/".

3. RUN crochet.sh as root

   $ sudo /bin/sh crochet.sh

   The script will first check that you have any needed sources.
   If you don't, the script will tell you exactly how to obtain the
   missing pieces.  Follow the instructions and re-run the script
   until you have everything.

   As soon as it finds all the required pieces, the script will then
   compile everything and build the disk image.  This part of the
   process can take several hours.

4. COPY the image to a suitable device (SD card, disk drive, etc)

   The script will suggest a 'dd' command to do this.

5. BOOT the image on your board.

   Again, read board/<board-name>/README for details.

***********************************************************

PROJECTS
------------

There are still plenty of ways this script could
be improved:

* More boards.  Currently, it supports Beaglebone, RaspberryPi, and
  PandaBoard.  There are a lot of other boards with similar concerns
  that could easily be supported.

* Non-ARM support.  I see no reason this script could not be used for
  other architectures.  I just haven't done so yet.

* Out-of-tree kernel configuration.  Right now, these scripts assume
  kernel configuration files are in the FreeBSD source tree.  I don't
  think config(8) requires this; it would be nice to be able to
  include a tweaked kernel configuration as part of a board
  definition.

* Package Installation.  I would like to be able to put a bunch of
  packages into board/NAME/packages and have them installed onto the
  image.  The nanobsd technique of using chroot won't work for
  cross-compiling.  Fortunately, the new pkgng tools do (mostly)
  support this; there are just a few minor bugs and small features
  needed for this to work: Ask on one of the mailing lists if you'd
  like to help extend pkgng to fully handle cross-architecture pkg
  installs.

* Swap.  The script should allow you to specify a swap size and
  automatically adjust the disk layout accordingly.  For now, board
  definitions are mostly creating swap files in the FreeBSD
  partition, which is easy and seems to work well enough.
  (Complicating factor: For several reasons, I would prefer a swap
  partition to precede the FreeBSD partition on the disk.)

* Support for read-only root and other more complex partitioning
  approaches.

* NanoBSD-style split-partition support.  Ideally, this would be a
  "mix in" capability that users could request with any board.
