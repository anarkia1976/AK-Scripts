#!/bin/bash
#
# AK Rom build script
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
magenta="\e[1;35m"
cyan="\e[1;36m"
yellow="\e[1;33m"
blue="\e[1;34m"
restore="\e[0m"
blink_red="\e[05;31m"
bold="\e[1m"
invert="\e[7m"

# rom source
ROM="DIRTY-DEEDS"
PLATFORM="NOUGAT"
DEVICE="du_angler-userdebug"

# local variables
CURRENT_DATE=`date +%Y%m%d`
CURRENT_TIME=`date +%H-%M-%S`
BUILD_LOG="/tmp/${CURRENT_DATE}_${CURRENT_TIME}_${ROM}.log"
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
CHG="No Build ~ No Party"

# path locations
HOME_DIR="${HOME}/ak-backup/rom"
ROM_DIR="du"

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

function hard_clean {
    cd ${HOME_DIR}/${ROM_DIR}
	echo -e "${bold}${blue}Hard Clean ==========================================================${restore}"
    ccache -c
    ccache -C
    make clobber
    make installclean
    . build/envsetup.sh
    lunch ${DEVICE}
    make clobber
    make installclean
	echo
} &>>$BUILD_LOG

function soft_clean {
    cd ${HOME_DIR}/${ROM_DIR}
	echo -e "${bold}${blue}Soft Clean ==========================================================${restore}"
    . build/envsetup.sh
    lunch ${DEVICE}
    make clobber
	echo
} &>>$BUILD_LOG

function make_sync {
    echo -e "${bold}${blue}Syncing ==========================================================${restore}"
    cd ${HOME_DIR}/${ROM_DIR}
    repo sync --force-sync ${THREAD}
	echo
} &>>$BUILD_LOG

function make_rom {
    cd ${HOME_DIR}/${ROM_DIR}
	echo -e "${bold}${blue}Building ==========================================================${restore}"
    . build/envsetup.sh
    lunch ${DEVICE}
    time mka bacon
	echo
} &>>$BUILD_LOG

function make_changelog {
    cd ${HOME_DIR}/${ROM_DIR}
	echo -e "${bold}${blue}Changelog ==========================================================${restore}"
	. generate_changelog.sh
	if [[ -e generate_changelog.sh ]]; then
        CHG="${CHANGELOG}"
    else
        CHG="Changelog Script is not present"
    fi
	echo
} &>>$BUILD_LOG

DATE_START=$(date +"%s")

if [[ ! -e ${BUILD_LOG} ]]; then
    touch ${BUILD_LOG}
fi

clear

echo
echo -en "${white}"
echo '======================================================================='
echo
echo -en "${red}"
echo '·▄▄▄▄  ▪  ▄▄▄  ▄▄▄▄▄ ▄· ▄▌    ▄• ▄▌ ▐ ▄ ▪   ▄▄·       ▄▄▄   ▐ ▄ .▄▄ · '
echo '██▪ ██ ██ ▀▄ █·•██  ▐█▪██▌    █▪██▌•█▌▐███ ▐█ ▌▪▪     ▀▄ █·•█▌▐█▐█ ▀. '
echo '▐█· ▐█▌▐█·▐▀▀▄  ▐█.▪▐█▌▐█▪    █▌▐█▌▐█▐▐▌▐█·██ ▄▄ ▄█▀▄ ▐▀▀▄ ▐█▐▐▌▄▀▀▀█▄'
echo '██. ██ ▐█▌▐█•█▌ ▐█▌· ▐█▀·.    ▐█▄█▌██▐█▌▐█▌▐███▌▐█▌.▐▌▐█•█▌██▐█▌▐█▄▪▐█'
echo '▀▀▀▀▀• ▀▀▀.▀  ▀ ▀▀▀   ▀ •      ▀▀▀ ▀▀ █▪▀▀▀·▀▀▀  ▀█▄▀▪.▀  ▀▀▀ █▪ ▀▀▀▀ '
echo
echo -en "${restore}"
echo -en "${white}"
echo '======================================================================='
echo ' AK ROM GENERATOR'
echo '======================================================================='
echo -en "${restore}"
echo
echo
echo
echo -en "${white}"
echo '======================================================================='
echo ' BUILD PLATFORM'
echo '======================================================================='
echo -en "${restore}"
echo
echo -en " ${bold}${blink_red}${ROM} ${PLATFORM}${restore}"
echo
echo
echo -en "${white}"
echo '======================================================================='
echo -en "${restore}"
echo
echo -en "${white}"
echo '======================================================================='
echo ' CLEANING'
echo '======================================================================='
echo -en "${restore}"
echo
while read -p "` echo -e " ${red}H${restore} (hard) / ${red}S${restore} (soft) / ${red}N${restore} (none) : "`" cchoice
do
case "${cchoice}" in
	h|H )
		echo
		start_spinner CLEANING 
		hard_clean 
		stop_spinner ALL DONE
		break
		;;
	s|S )
		echo
		start_spinner CLEANING 
		soft_clean 
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
echo '======================================================================='
echo -en "${restore}"
echo
echo -en "${white}"
echo '======================================================================='
echo ' SYNCING'
echo '======================================================================='
echo -en "${restore}"
echo
while read -p "` echo -e " ${red}Y${restore} (yes) / ${red}N${restore} (no) : "`" cchoice
do
case "${cchoice}" in
	y|Y )
		echo
		start_spinner SYNCING 
		make_sync
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
echo '======================================================================='
echo -en "${restore}"
echo
echo -en "${white}"
echo '======================================================================='
echo ' BUILDING'
echo '======================================================================='
echo -en "${restore}"
echo
while read -p "` echo -e " ${red}Y${restore} (yes) / ${red}N${restore} (no) : "`" dchoice
do
case "${dchoice}" in
	y|Y)
		echo
		start_spinner BUILDING
        make_rom
		make_changelog
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
echo '======================================================================='
echo -en "${restore}"
echo
echo -en "${white}"
echo '======================================================================='
echo ' ALL DONE'
echo '======================================================================='
echo -en "${restore}"
echo
DATE_END=$(date +"%s")
DIFF=$((${DATE_END} - ${DATE_START}))
echo -e "${red}DEVICE${restore}    : ${DEVICE}"
echo -e "${red}TIME${restore}      : $((${DIFF} / 60)) minute(s) and $((${DIFF} % 60)) second(s)"
echo -e "${red}CHANGELOG${restore} : ${CHG}"
echo -e "${red}BUILD LOG${restore} : ${BUILD_LOG}"
echo
echo -en "${white}"
echo '======================================================================='
echo -en "${restore}"
echo
