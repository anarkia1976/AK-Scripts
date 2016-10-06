#!/bin/bash

#************************************************#
#                                                #
#                   AK Kernel                    #
#               release generator                #
#                by @anarkia1976                 #
#                                                #
#************************************************#

# colors
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

# path and resources
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
KERNEL="Image.gz"
DTBIMAGE="dtb"
DEFCONFIG="ak_angler_defconfig"
KERNEL_DIR=`pwd`
ZIMAGE_DIR="arch/arm64/boot"
ANYKERNEL_DIR="AK-UnicornBlood-AnyKernel2"
OUT_DIR="AK-releases"
TOOLCHAIN_DIR="AK-uber64-4.9"

ANYKERNEL_TOOLS_DIR="$KERNEL_DIR/../$ANYKERNEL_DIR/tools"
ANYKERNEL_MODULE_DIR="$KERNEL_DIR/../$ANYKERNEL_DIR/modules"
ANYKERNEL_REPACK_DIR="$KERNEL_DIR/../$ANYKERNEL_DIR"
ANYKERNEL_OUT_DIR="$KERNEL_DIR/../$OUT_DIR"

# kernel release version
AK_VER="AK.003.N.ANGLER"

# vars
export LOCALVERSION=~`echo $AK_VER`
export CROSS_COMPILE="$KERNEL_DIR/../$TOOLCHAIN_DIR/bin/aarch64-linux-android-"
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=ak
export KBUILD_BUILD_HOST=kernel

# Functions
function clean_all {
		#echo; ccache -c -C echo;
		if [ -f "$ANYKERNEL_MODULE_DIR/*.ko" ]; then
			rm `echo $ANYKERNEL_MODULE_DIR"/*.ko"`
		fi
		cd $ANYKERNEL_REPACK_DIR
		rm -rf zImage
		rm -rf $DTBIMAGE
		git reset --hard > /dev/null 2>&1
		git clean -f -d > /dev/null 2>&1
		cd $KERNEL_DIR
		echo
		make clean && make mrproper
}

function make_kernel {
		echo
		make $DEFCONFIG
		make $THREAD
		cp -vr $ZIMAGE_DIR/$KERNEL $ANYKERNEL_REPACK_DIR/zImage
}

function make_modules {
		if [ -f "$ANYKERNEL_MODULE_DIR/*.ko" ]; then
			rm `echo $ANYKERNEL_MODULE_DIR"/*.ko"`
		fi
		find $KERNEL_DIR -name '*.ko' -exec cp -v {} $ANYKERNEL_MODULE_DIR \;
}

function make_dtb {
		$ANYKERNEL_TOOLS_DIR/dtbToolCM -v2 -o $ANYKERNEL_REPACK_DIR/$DTBIMAGE -s 2048 -p scripts/dtc/ arch/arm64/boot/dts/
}

function make_zip {
		cd $ANYKERNEL_REPACK_DIR
		zip -x@zipexclude -r9 `echo $AK_VER`.zip *
		mv  `echo $AK_VER`.zip $ANYKERNEL_OUT_DIR
		cd $KERNEL_DIR
}

DATE_START=$(date +"%s")

clear

echo -e "${green}"
echo "                                            ";
echo "   ___   __     __ __                 __    ";
echo "  / _ | / /__  / //_/__ ___  _______ / /    ";
echo " / __ |/  '_/ / ,< / -_) _ \/ __/ -_) /     ";
echo "/_/ |_/_/\_\ /_/|_|\__/_//_/_/  \__/_/      ";
echo "    / ___/__ ___  ___ _______ _/ /____  ____";
echo "   / (_ / -_) _ \/ -_) __/ _ \`/ __/ _ \/ __/";
echo "   \___/\__/_//_/\__/_/  \_,_/\__/\___/_/   ";
echo "                                            ";
echo "                                            ";

echo "----------------"
echo " Kernel Release"
echo "----------------"

echo -e "${red}"; echo -e "${blink_red}"; echo " $AK_VER"; echo -e "${restore}";

echo -e "${green}"
echo "---------------"
echo " Making Kernel "
echo "---------------"
echo -e "${restore}"

while read -p "Do you want to clean stuffs (y/n)? " cchoice
do
case "$cchoice" in
	y|Y )
		clean_all
		echo
		echo "All Cleaned now."
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

echo

while read -p "Do you want to build kernel (y/n)? " dchoice
do
case "$dchoice" in
	y|Y)
		make_kernel
		make_dtb
		make_modules
		make_zip
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

echo -e "${green}"
echo "-----------------"
echo " Build Completed "
echo "-----------------"
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo

