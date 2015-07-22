#
# Support for ZedBoard and possibly other Xilinx Zynq-7000 platforms.
#
# Based on Thomas Skibo's information from
# http://www.thomasskibo.com/zedbsd/
#

KERNCONF=ZEDBOARD
UBLDR_LOADADDR=0x2000000
ZYNQ_UBOOT_PATCH_VERSION="xlnx"
ZYNQ_UBOOT_SRC=${TOPDIR}/u-boot-${ZYNQ_UBOOT_PATCH_VERSION}
ZYNQ_PS7_INIT=ps7_init
IMAGE_SIZE=$((1000 * 1000 * 1000))	# 1 GB default
TARGET_ARCH=armv6

zynq_check_uboot ( ) {
    uboot_set_patch_version ${ZYNQ_UBOOT_SRC} ${ZYNQ_UBOOT_PATCH_VERSION}

    uboot_test \
    	ZYNQ_UBOOT_SRC \
	"$ZYNQ_UBOOT_SRC/board/xilinx/zynq/Makefile" \
	"git clone -b xilinx-v2014.4 git://github.com/Xilinx/u-boot-xlnx.git ${ZYNQ_UBOOT_SRC}"

    # Apply patches
    strategy_add $PHASE_BUILD_OTHER uboot_patch ${ZYNQ_UBOOT_SRC} `uboot_patch_files`

    # Copy over automatically generated ps7 initialization routines into
    # u-boot build directory.  These files are Zedboard specific.
    strategy_add $PHASE_BUILD_OTHER cp ${BOARDDIR}/files/${ZYNQ_PS7_INIT}.h \
	${ZYNQ_UBOOT_SRC}/board/xilinx/zynq/ps7_init.h
    strategy_add $PHASE_BUILD_OTHER cp ${BOARDDIR}/files/${ZYNQ_PS7_INIT}.c \
	${ZYNQ_UBOOT_SRC}/board/xilinx/zynq/ps7_init.c

    # Config and build
    strategy_add $PHASE_BUILD_OTHER uboot_configure ${ZYNQ_UBOOT_SRC} zynq_zed_config
    strategy_add $PHASE_BUILD_OTHER uboot_build ${ZYNQ_UBOOT_SRC}
}
strategy_add $PHASE_CHECK zynq_check_uboot

zynq_check_python ( ) {
    if python --version >/dev/null 2>&1; then
        true
    else
        echo "Need Python to run Xilinx Zynq BIN utility."
        echo
        echo "Install Python from port or package."
        echo
        echo "Run this script again after you have the files."
        exit 1
    fi
}
strategy_add $PHASE_CHECK zynq_check_python

# ZedBoard requires a FAT partition to hold the boot loader bits.
zedboard_partition_image ( ) {
    disk_partition_mbr
    disk_fat_create 64m
    disk_ufs_create
}
strategy_add $PHASE_PARTITION_LWW zedboard_partition_image

zedboard_populate_boot_partition ( ) {
    # u-boot files
    cp ${ZYNQ_UBOOT_SRC}/boot.bin .
    cp ${ZYNQ_UBOOT_SRC}/u-boot.img .

    # FDT files
    freebsd_install_fdt zedboard.dts zedboard.dts
    freebsd_install_fdt zedboard.dts zedboard.dtb

    # ubldr
    freebsd_ubldr_copy_ubldr .

    # Extra boot files (uEnvt.txt is all for now)
    cp ${BOARDDIR}/bootfiles/* .
}
strategy_add $PHASE_BOOT_INSTALL zedboard_populate_boot_partition

# Build and install ubldr from source
strategy_add $PHASE_BUILD_OTHER freebsd_ubldr_build UBLDR_LOADADDR=${UBLDR_LOADADDR}

strategy_add $PHASE_FREEBSD_BOARD_INSTALL board_default_installkernel .
strategy_add $PHASE_FREEBSD_BOARD_INSTALL mkdir -p boot/msdos

# ubldr help file goes on the UFS partition (after boot dir is created)
strategy_add $PHASE_FREEBSD_BOARD_INSTALL freebsd_ubldr_copy_ubldr_help boot
