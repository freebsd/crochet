# Crochet-FreeBSD


Crochet is a tool for building bootable FreeBSD images.
This tool was formerly known as "freebsd-beaglebone" or
"beaglebsd" as the original work was done for BeagleBone.
But it now supports more boards and should easily extend
to support many more.

## FAQ


### How do I log in via ssh?


The default configuration of FreeBSD doesn't allow root to log in over ssh.  You have two options

* You can use [option User](https://github.com/freebsd/crochet/tree/master/option/User) in your Crochet configuration file to create a non-root user than can log in over ssh.

* If your platform has a serial console, log into the console using a serial cable and create yourself a user other than root.

### Why is nothing showing up on my HDMI or VGA monitor?

Not every platform supports HDMI or VGA yet.  Most platforms support RS-232.

### How do I install 3rd party applications?

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

## Supported Platforms


* [Alix](http://pcengines.ch/alix.htm)
* [BananaPi](http://www.bananapi.org/)
* [BananaPi BPI-M3](http://www.banana-pi.org/m3.html)
* [BeagleBone](http://beagleboard.org/)
* [Chromebook Snow](http://www.samsung.com/ca/consumer/office/chrome-devices/chromebooks/XE303C12-A01CA)
* [Cubieboard](http://cubieboard.org/)
* [OrangePi](http://www.orangepi.org)
* [PandaBoard](http://pandaboard.org/)
* [Pine64](https://www.pine64.org/)
* [RaspberryPi and RaspberryPi 2](http://www.raspberrypi.org/)
* [Soekris](http://soekris.com/)
* generic x86 systems.
* [Wandboard](http://wandboard.org/)
* [Versatile PB](http://arm.com/products/tools/development-boards/versatile/)
* [VMWare](http://www.vmware.com/)
* [ZedBoard](http://www.zedboard.org/)
* [Zybo](http://digilentinc.com/zybo)

## How to Build a Disk Image

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

## Command-line Options

* -b <board>: Load standard configuration for board
* -c <file>: Load configuration from file
* -e <email>: Email address to receive build status
* -u: Update source tree

## Using pkg

You can use `pkg` to install packages on your final crochet image if you have your own package repository. Add the following to your config:

```
# Package Installation Information

option PackageInit $pkg-repo
option Package security/sudo

# If you don't put a custom resolv.conf in your overlay use this
# Otherwise pkg will not be able to resolv hostnames

option Resolv
```
In the example above, change `$pkg-repo` to the full URL of your package repository. Be sure to include the category for the package. Ex: `security/sudo` vs. `sudo`. You can also specify more than one package at a time. Ex: `option Package security/sudo sysutils/tmux`. In order for `pkg` to communicate with a remote package repo, you either need a custom `resolv.conf` in your board overlay, or use `option Resolv` in your config. 

## Potential Projects

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

## Tracking FreeBSD-CURRENT with VMWare Fusion and Crochet

Some time back, I added some code to Crochet to build VMWare images directly.  I recently had a spare MacBook sitting in my office and decided to try using this as a way to track FreeBSD-CURRENT.

So far, it seems to work pretty well; I thought I'd share what I've done so far and see if other people have ideas for improving this.

Warning:  I've tried to be complete, but I know the following instructions omit a lot of details.  I've listed some of the known bugs at the bottom of this article.  Help in fixing them is appreciated.

Basic idea:
* Share /Users between Mac OS and FreeBSD VMs.
* Run Crochet inside a FreeBSD VM to build the next FreeBSD VM.

Since /Users is shared, this allows you to build and boot a new
VM with a new FreeBSD version and then run the new system
with the same work environment.

### Get your first FreeBSD VM running with shared /Users

1) Configure Mac OS with a case-sensitive filesystem. This generally requires reinstalling Mac OS completely from scratch; please ask on a Mac forum if you don't know how to do this.

2) Install VMWare Fusion.  (No reason this shouldn't be feasible with Parallels or VirtualBox, but Crochet doesn't yet build correct Parallels or VirtualBox VMs.)

3) Set up NFS export of /Users on the Mac to VMWare images. My /etc/exports on the Mac looks like this:

    /Users -alldirs -maproot=root -network 192.168.177.0 -mask 255.255.255.0
    /Users -alldirs -maproot=root -network 172.16.158.0 -mask 255.255.255.0

4) Get the first FreeBSD VM running somehow.  (I installed from DVD image.)

5) Edit FreeBSD /etc/fstab to mount /Users from the Mac by adding this line:

    192.168.177.1:/Users /Users hfs rw 0 0

6) Enable NFSv3 client support on FreeBSD (Mac OS doesn't serve NFSv4) by enabling lockd/statd on FreeBSD in rc.conf:

    rpc_lockd_enable="YES"
    rpc_statd_enable="YES"
    nfs_client_enable="YES"

7) Add an account to FreeBSD that matches your home account on the Mac:
* Same name
* Same UID, GID
* Same home directory: /Users/_account_/

Verify:  After rebooting the FreeBSD VM, you should be able to log into the same account on FreeBSD or Mac, edit files in either place, etc.

Verify: Make sure you can do SVN checkouts and updates in either place.  You'll need to verify you have the same version of SVN on either side.  Mysterious SVN failures are probably due to NFS locking; SVN does not have clear error messages when it can't get file locks.

A twist:  You can also build your first FreeBSD VM on any other FreeBSD system you happen to have available instead of installing a new VM from DVD.  Recently, I built a FreeBSD VMWare image on my BeagleBone (cross-building i386 from ARM) and then copied the result over to my Mac.

### Build a new FreeBSD VM with your old FreeBSD VM

1) Get a copy of Crochet:

    git clone https://github.com/kientzle/crochet-freebsd.git

2) Adjust the vmware.config.sh file at the bottom of this article to match your expectations.

3) Check out FreeBSD source into the Crochet directory:

    cd crochet-freebsd
    svn co http://svn.freebsd.org/base/head src

Note:  If you have everything set up properly, you should be able to perform the above three steps from Mac OS or FreeBSD.  (On FreeBSD, use the built-in 'svnlite' command instead of installing the standard subversion package.)

4) Build a new VM on FreeBSD:

    ./crochet -c vmware.config.sh

This should put the new VM into a directory called

    FreeBSD-CURRENT-i386-GENERIC-r<revision>.vmwarevm

This may take a couple of hours depending on how fast your machine is.

At this point, you should be able to open the new VM from the Mac side and have it "just work."

### Keep Climbing

In particular, you can now log into the VM you just built and use it to build the next one:

    cd crochet-freebsd
    svnlite up src
    rm -rf work/*
    ./crochet -c vmware.config.sh

Each new VM is a completely clean "from scratch" system
build, so this approach avoids propagating any leftover
detritus from old systems.

You can keep the old VMs around as long as you like (simplifies bisecting
to find bugs) and even have multiple versions running at once.
If you have a problem with one, you can suspend it until
you have time to dig into that issue.

This does require a fair bit of disk space for each VM, you
should probably experiment with the ImageSize setting to
see how small you can make it while still having a useful
system.

### Known Issues with the Above

* I've not yet come up with a completely satisfactory way to share ports/packages across VMs.

* VMWare launches VMs with a big "VMWare" boot splash that doesn't go away.  I've found it necessary to start a new VM and immediately suspend/resume it before I can see the FreeBSD console.  If you figure out how to fix this, I'm very interested.  (This problem seems to have gone away since I updated to VMWare Fusion 5.0.5.  Maybe it was a VMWare bug?)

* NFSv3 file locking is not particularly robust and SVN requires good file locking.  Mac OS seems to stop the lock daemon periodically which stalls a lot of NFS requests until it restarts.  As a result, I generally find it easier to do SVN operations from Mac OS rather than FreeBSD.  Alternatively, git seems to work better over NFS than SVN does.

* It needs a little manual effort to keep UIDs, GIDs, etc, consistent across Mac and FreeBSD environments.

* I've gotten confused a few times typing a command into the wrong window.  In particular, Mac OS cannot run Crochet.  :-)

### Crochet configuration file: vmware.config.sh 

    # vmware.config.sh

    # Find out the current FreeBSD revision and decide the
    # name of the VM and the directory where it will go.
    SVNVERSION=`svnlite info src | grep "Last Changed Rev" | sed -e 's/.*: *//'`
    BASEIMG=FreeBSD-CURRENT-i386-GENERIC-r${SVNVERSION}
    VMDIR=/Users/kientzle/projects/FreeBSD/VMWare/${BASEIMG}.vmwarevm

    # Ask Crochet for a standard I386 build in a VMWare VM    
    board_setup VMWareGuest
    option VMWareDir ${VMDIR}
    option VMWareName ${BASEIMG}
    option ImageSize 8g

    # Look for FreeBSD src in the Crochet dir.
    FREEBSD_SRC=${TOPDIR}/src

    IMG=${WORKDIR}/${BASEIMG}.img

    # After the basic image has been assembled, update some of the files.    
    customize_freebsd_partition ( ) {
        # TODO: Find a good way to add swap.

        # Use the SVN revision as the hostname.    
        echo 'hostname="r'$SVNVERSION'"' >> etc/rc.conf
    
        # Enable some useful things in /etc/rc.conf
        cat <<"EOF" >>etc/rc.conf
    sshd_enable="YES"
    ntpd_enable="YES"
    rpc_lockd_enable="YES"
    rpc_statd_enable="YES"
    nfs_client_enable="YES"
    EOF
    
        # Mount Mac /Users onto FreeBSD /Users
        mkdir Users
        echo '192.168.177.1:/Users /Users nfs rw 0 0' >> etc/fstab

        # Propagate the passwd file to the next VM.
        cp /etc/master.passwd etc/master.passwd
        pwd_mkdb -p -d `pwd`/etc etc/master.passwd
    
        # Tell ntp to step clock by as much as necessary;
        # Otherwise, NTP will stop working if a VM is suspended for a while.
        echo 'tinker panic 0' >> etc/ntp.conf
    }

    # After the VM is complete, update the ownership.    
    customize_post_unmount ( ) {
    	chown -R kientzle:staff ${VMDIR}
    }
    
    # End of file.



