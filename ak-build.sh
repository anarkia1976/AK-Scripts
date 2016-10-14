#!/bin/bash

##************************************************##
##************************************************##
## Kernel build script                            ##
## author: @anarkia1976                           ##
##                                                ##
## Shell spinner function                         ##
## author: tasos latsas                           ##
##************************************************##
##************************************************##


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
TOOLCHAIN_DIR="AK-uber64-4.9-linaro"

ANYKERNEL_TOOLS_DIR="$KERNEL_DIR/../$ANYKERNEL_DIR/tools"
ANYKERNEL_MODULE_DIR="$KERNEL_DIR/../$ANYKERNEL_DIR/modules"
ANYKERNEL_REPACK_DIR="$KERNEL_DIR/../$ANYKERNEL_DIR"
ANYKERNEL_OUT_DIR="$KERNEL_DIR/../$OUT_DIR"

# kernel release version
AK_VER="AK.666.N.ANGLER"

# vars
export LOCALVERSION=~`echo $AK_VER`
export CROSS_COMPILE="$KERNEL_DIR/../$TOOLCHAIN_DIR/bin/aarch64-linux-android-"
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=ak
export KBUILD_BUILD_HOST=kernel

# functions
function _spinner() {

    # $1 start/stop
    #
    # on start: $2 display message
    # on stop : $2 process exit status
    #           $3 spinner function pid (supplied from stop_spinner)

    local on_success="DONE"
    local on_fail="FAIL"
    local white="\e[1;37m"
    local green="\e[1;32m"
    local red="\e[1;31m"
    local nc="\e[0m"

    case $1 in
        start)
            # calculate the column where spinner and status msg will be displayed
            let column=$(tput cols)-${#2}-256
            # display message and position the cursor in $column column
            echo -ne ${2}
            printf "%${column}s"

            # start spinner
            i=1
            sp='\|/-'
            delay=0.15

            while :
            do
                printf "\b${sp:i++%${#sp}:1}"
                sleep $delay
            done
            ;;
        stop)
            if [[ -z ${3} ]]; then
                echo "spinner is not running.."
                exit 1
            fi

            kill $3 > /dev/null 2>&1

            # inform the user uppon success or failure
            echo -en "\b[ "
            if [[ $2 -eq 0 ]]; then
                echo -en "${green}${on_success}${nc}"
            else
                echo -en "${red}${on_fail}${nc}"
            fi
            echo -e " ]"
            ;;
        *)
            echo "invalid argument, try {start/stop}"
            exit 1
            ;;
    esac
}

function start_spinner {
    # $1 : msg to display
    _spinner "start" "${1}" &
    # set global spinner pid
    _sp_pid=$!
    disown
}

function stop_spinner {
    # $1 : command exit status
    _spinner "stop" $1 $_sp_pid
    unset _sp_pid
}


function clean_all {
		if [ -f "$ANYKERNEL_MODULE_DIR/*.ko" ]; then
			rm `echo $ANYKERNEL_MODULE_DIR"/*.ko"` > /dev/null 2>&1
		fi
		cd $ANYKERNEL_REPACK_DIR
		rm -rf zImage
		rm -rf $DTBIMAGE
		git reset --hard > /dev/null 2>&1
		git clean -f -d > /dev/null 2>&1
		cd $KERNEL_DIR
		make clean > /dev/null 2>&1 && make mrproper > /dev/null 2>&1
}

function make_kernel {
		make $DEFCONFIG > /dev/null 2>&1
		make $THREAD > /dev/null 2>&1
		cp -vr $ZIMAGE_DIR/$KERNEL $ANYKERNEL_REPACK_DIR/zImage > /dev/null 2>&1
}

function make_modules {
		if [ -f "$ANYKERNEL_MODULE_DIR/*.ko" ]; then
			rm `echo $ANYKERNEL_MODULE_DIR"/*.ko"` > /dev/null 2>&1
		fi
		find $KERNEL_DIR -name '*.ko' -exec cp -v {} $ANYKERNEL_MODULE_DIR \; > /dev/null 2>&1
}

function make_dtb {
		$ANYKERNEL_TOOLS_DIR/dtbToolCM -v2 -o $ANYKERNEL_REPACK_DIR/$DTBIMAGE -s 2048 -p scripts/dtc/ arch/arm64/boot/dts/  > /dev/null 2>&1
}

function make_zip {
		cd $ANYKERNEL_REPACK_DIR
		zip -x@zipexclude -r9 `echo $AK_VER`.zip * > /dev/null 2>&1
		mv  `echo $AK_VER`.zip $ANYKERNEL_OUT_DIR > /dev/null 2>&1
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
		echo
		start_spinner CLEANING
		clean_all
		stop_spinner ALL DONE
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
		echo
		start_spinner BUILDING
		make_kernel
		make_dtb
		make_modules
		make_zip
		stop_spinner ALL DONE
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

