#!/bin/bash
#
# AK Kernel build script
#
# Copyright (C) 2016 @anarkia1976
#
# spinner author: @tlatsas (https://github.com/tlatsas)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

# colors
white="\e[1;37m"
green="\e[1;32m"
red="\e[1;31m"
restore="\e[0m"
blink_red="\e[05;31m"
bold="\e[1m"
invert="\e[7m"

# kernel release
AK_VER="AK.666.N.ANGLER"

# resources
CURRENT_DATE=`date +%Y%m%d`
KERNEL_DIR=`pwd`
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
KERNEL="Image.gz"
DTB="dtb"
DEFCONFIG="ak_angler_defconfig"

# extra paths
BUILD_LOG="/tmp/${AK_VER}_${CURRENT_DATE}.log"
ZIMAGE_DIR="arch/arm64/boot"
OUT_DIR="AK-releases"
TOOLCHAIN_DIR="AK-uber64-4.9-linaro"

# anykernel paths
ANYKERNEL_DIR="AK-UnicornBlood-AnyKernel2"
ANYKERNEL_TOOLS_DIR="$KERNEL_DIR/../$ANYKERNEL_DIR/tools"
ANYKERNEL_MODULE_DIR="$KERNEL_DIR/../$ANYKERNEL_DIR/modules"
ANYKERNEL_REPACK_DIR="$KERNEL_DIR/../$ANYKERNEL_DIR"
ANYKERNEL_OUT_DIR="$KERNEL_DIR/../$OUT_DIR"

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

    local on_success="SUCCESS"
    local on_fail="FAILED"

    case $1 in
        start)
            # calculate the column where spinner and status msg will be displayed
            let column=$(tput cols)-${#2}-256
            # display message and position the cursor in $column column
            echo -ne "     ... ${2}"
            printf "%${column}s"

            # start spinner
            i=1
            sp='\|/-'
            delay=0.3

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
                echo -en "${green}${on_success}${restore}"
            else
                echo -en "${red}${on_fail}${restore}"
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
		cd $ANYKERNEL_REPACK_DIR
		rm -rf modules/*.ko
		rm -rf zImage
		rm -rf $DTB
		git reset --hard >> $BUILD_LOG 2>&1
		git clean -f -d >> $BUILD_LOG 2>&1
		cd $KERNEL_DIR
		make clean >> $BUILD_LOG 2>&1
		make mrproper >> $BUILD_LOG 2>&1
}

function make_kernel {
		make $DEFCONFIG >> $BUILD_LOG 2>&1
		make $THREAD >> $BUILD_LOG 2>&1
		cp -vr $ZIMAGE_DIR/$KERNEL $ANYKERNEL_REPACK_DIR/zImage >> $BUILD_LOG 2>&1
}

function make_modules {
		rm -rf $ANYKERNEL_MODULE_DIR/*.ko
		find $KERNEL_DIR -name '*.ko' -exec cp -v {} $ANYKERNEL_MODULE_DIR \; >> $BUILD_LOG 2>&1
}

function make_dtb {
		$ANYKERNEL_TOOLS_DIR/dtbToolCM -v2 -o $ANYKERNEL_REPACK_DIR/$DTB -s 2048 -p scripts/dtc/ arch/arm64/boot/dt/ >> $BUILD_LOG 2>&1
}

function make_zip {
		cd $ANYKERNEL_REPACK_DIR
		zip -x@zipexclude -r9 `echo $AK_VER`.zip * >> $BUILD_LOG 2>&1
		mv  `echo $AK_VER`.zip $ANYKERNEL_OUT_DIR >> $BUILD_LOG 2>&1
		cd $KERNEL_DIR
}

DATE_START=$(date +"%s")

clear

echo
echo -en "${white}"
echo '============================================'
echo
echo -en "${red}"
echo '                      :::!~!!!!!:.'
echo '                  .xUHWH!! !!?M88WHX:.'
echo '                .X*#M@$!!  !X!M$$$$$$WWx:.'
echo '               :!!!!!!?H! :!$!$$$$$$$$$$8X:'
echo '              !!~  ~:~!! :~!$!#$$$$$$$$$$8X:'
echo '             :!~::!H!<   ~.U$X!?R$$$$$$$$MM!'
echo '             ~!~!!!!~~ .:XW$$$U!!?$$$$$$RMM!'
echo '               !:~~~ .:!M"T#$$$$WX??#MRRMMM!'
echo '               ~?WuxiW*`   `"#$$$$8!!!!??!!!'
echo '             :X- M$$$$       `"T#$T~!8$WUXU~'
echo '            :%`  ~#$$$m:        ~!~ ?$$$$$$'
echo '          :!`.-   ~T$$$$8xx.  .xWW- ~""##*'
echo '.....   -~~:<` !    ~?T#$$@@W@*?$$      /`'
echo 'W$@@M!!! .!~~ !!     .:XUW$W!~ `"~:    :'
echo '#"~~`.:x%`!!  !H:   !WM$$$$Ti.: .!WUn+!`'
echo ':::~:!!`:X~ .: ?H.!u "$$$B$$$!W:U!T$$M~'
echo '.~~   :X@!.-~   ?@WTWo("*$$$W$TH$! `'
echo 'Wi.~!X$?!-~    : ?$$$B$Wu("**$RM!'
echo '$R@i.~~ !     :   ~$$$$$B$$en:``'
echo '?MXT@Wx.~    :     ~"##*$$$$M~'
echo
echo -en "${restore}"
echo -en "${white}"
echo '============================================'
echo ' AK KERNEL GENERATOR                        '
echo '============================================'
echo -en "${restore}"
echo
echo
echo
echo -en "${white}"
echo '============================================'
echo ' BUILD VERSION                              '
echo '============================================'
echo -en "${restore}"
echo
echo -en " ${bold}${blink_red}$AK_VER${restore}"
echo
echo
echo -en "${white}"
echo '============================================'
echo -en "${restore}"
echo
echo
echo

echo -en "${white}"
echo '============================================'
echo ' CLEANING                                   '
echo '============================================'
echo -en "${restore}"
echo
while read -p " Y / N : " cchoice
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
		echo "     ... INVALID TRY AGAIN ..."
		echo
		;;
esac
done
echo
echo -en "${white}"
echo '============================================'
echo -en "${restore}"
echo
echo
echo

echo -en "${white}"
echo '============================================'
echo ' BUILDING                                   '
echo '============================================'
echo -en "${restore}"
echo
while read -p " Y / N : " dchoice
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
		echo "     ... INVALID TRY AGAIN ..."
		echo
		;;
esac
done
echo
echo -en "${white}"
echo '============================================'
echo -en "${restore}"
echo
echo
echo

echo -en "${white}"
echo '============================================'
echo ' ALL DONE                                   '
echo '============================================'
echo -en "${restore}"
echo
DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo
echo -en "${white}"
echo '============================================'
echo -en "${restore}"
echo
echo
echo

