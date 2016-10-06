#!/bin/bash


#************************************************#
#          kernel changelog generator            #
#           modded by @anarkia1976               #
#           written by @fusionjack               #
#************************************************#

# colorize and add text parameters
grn=$(tput setaf 2)             # green
red=$(tput setaf 1)             # red
txtbld=$(tput bold)             # bold
bldblu=${txtbld}$(tput setaf 4) # blue
txtrst=$(tput sgr0)             # reset

# variables
rdir=`pwd`
CURRENT_DATE=`date +%Y%m%d`
LAST_DATE=`date +%s -d "15 day ago"`
CUSTOM_DATE="$1"

# generate changelog
echo -e "${bldblu}Generating changelog ${txtrst}"
if [ -z "$CUSTOM_DATE" ]; then
    if [ -z "$LAST_DATE" ]; then
        WORKING_DATE=`date +%s "1 day ago"`
    else
        WORKING_DATE=${LAST_DATE}
    fi
else
    WORKING_DATE=${CUSTOM_DATE}
fi

CHANGELOG=$rdir/changelog_${CURRENT_DATE}.txt

# remove existing changelog
file="$CHANGELOG"
if [ -f "$file" ]; then
    echo -e "${red}Removing existing changelog${txtrst}"
    rm $CHANGELOG;
fi

# find the directories to log
find $rdir -name .git | sed 's/\/.git//g' | sed 'N;$!P;$!D;$d' | while read line
do
    cd $line
    # test to see if the repo needs to have a changelog written.
    log=$((git log --pretty="* %s (%an) [%h]" --no-merges --since=$WORKING_DATE --date-order) | sed 's/\.git//')
    project=$(git remote -v | grep -i origin | head -n1 | awk '{print $2}' | sed 's/.*\///' | sed 's/\.git//')
    if [ ! -z "$log" ]; then
        # write the changelog
	echo -e "${grn}$project is updated ${txtrst}"
        echo "Project name: $project" >> $CHANGELOG
        echo "$log" | while read line
        do
		echo "  $line" >> $CHANGELOG
        done
        echo "" >> $CHANGELOG
    fi
done
