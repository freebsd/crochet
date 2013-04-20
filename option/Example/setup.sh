# Example option and documentation.

# Within a user configuration, a line
#
#     option Example arg1 arg2
#
# results in option/Example/setup.sh being run with
# the specified arguments.
#
# This can be used in a wide variety of different ways:
#
# 1) Shortcuts for defining variables.
#
# For example, the ImageSize option simply provides
# syntactic sugar for setting the IMAGE_SIZE variable.
#
# 2) Adding features to the build.
#
# For example, the UsrSrc option registers a function to be run late
# in the install process that copies the FreeBSD source tree to
# /usr/src on the constructed image.
#
# Options can use the same strategy_add mechanism used by
# board definitions to register shell commands to be run
# at different points in the build.  See board/NewBoardExample/setup.sh
# and lib/base.sh for more explanation of the strategy_add mechanism.
#
# The simplest and most common use of the strategy_add mechanism
# is to add a shell command to be run during the installation phase
# after the basic installation is complete.
#
# This usually looks like the following:
#
# my_option_work ( ) {
#   # Useful trivia:
#   # * OPTIONDIR is set to the directory with the Option files
#   # * cwd is set to the root of the installed system
#
#   cp ${OPTIONDIR}/myconfigfile ./etc/
#   echo 'new rc.conf entry' > ./etc/rc.conf
# }
# strategy_add $PHASE_FREEBSD_OPTION_INSTALL my_option_work
#
# Options run with OPTIONDIR set to the full path of the
# option/<Option>/ directory, so you can put additional files in that
# directory (such as special rc.d files to be copied to the final
# image).  option/AutoSize has an example of this.
#
# Options can do anything that board definitions can do: they can test
# for the presence of sources or tools, build software, install, and
# can even alter the way the image is built or partitioned.
#
# Options generally register in PHASE_FREEBSD_OPTION_INSTALL which
# runs after the board-specific installation.  In this phase, options
# can access and modify the basic system installed by the board:
# * add lines to etc/rc.conf
# * add lines to etc/fstab
# * edit other configuration files in etc
# * install packages
# * create or modify user accounts
#
# However, if you are trying to build an option that is inherently
# board-specific (for example, anything that attempts to modify the
# boot process or image partitioning is probably board-specific), it
# should be registered underneath the board directory.  Among other
# details, such options have access to the BOARDDIR variable.
