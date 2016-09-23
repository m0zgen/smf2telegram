#!/bin/bash
# Publish new posts from SMF forum in to toTelegram
# Author: Yevgeniy Goncharov aka xck, http://sys-adm.in

# ---------------------------------------------------------- VARIABLES #
# Env and paths
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)

# DATA SETTINGS #
SOURCE="http://forum.sys-admin.kz"

SOURCEFILE="$SCRIPT_PATH/sfile.html"
POSTFILE="$SCRIPT_PATH/pfile.html"

TEMPARRAY=()
prevLink=()

# BOT SETTINGS #
CHATID="<ID>"
KEY="<TOKEN>"

# ---------------------------------------------------------- ACTIONS #

# Download source and extract html element contain all last posts
curl -H 'Cache-Control: no-cache' -s $SOURCE > $SOURCEFILE && sed -i -n '/<dl id=\"ic_recentposts\"/,/<\/dl>/p' $SOURCEFILE

# Extract clean links into array
LINKS=(`cat $SOURCEFILE | grep "dt><strong><a href=" | sed "s/<a href/\\n<a href/g" | sed 's/\"/\"><\/a>\n/2' | grep "topic=" | sed -e 's/\(index.php?\).*\(topic=\)/\1\2/' | sed 's/.*href=\"//g' | sed 's/\">.*//' `)

if [ ! -f $POSTFILE ]; then
    touch $POSTFILE
    echo ${LINKS[*]} > $POSTFILE
  else

      # Load previous saved links array
      prevLink=(`cat $POSTFILE`)

		# Sort uniq valuse from bot arrays
		TEMPARRAY=(`echo ${LINKS[@]} ${prevLink[@]} | tr ' ' '\n' | sort | uniq -u`)

		# Loop sorted array
		for i in ${TEMPARRAY[@]}; do

			# Check exist values
			if [[ " ${LINKS[@]} " =~ " ${i} " ]]; then

				echo "Send to Telegram!"

          # First variant
          # curl -s --max-time 10 -d "chat_id=$CHATID&disable_web_page_preview=1&text=$i" https://api.telegram.org/bot$KEY/sendMessage >/dev/null

          # Second variant
		    	curl -s -X POST https://api.telegram.org/bot$KEY/sendMessage \
	     	    -d text="Update on forum: $i" \
	     	    -d chat_id="$CHATID" >/dev/null
		        sleep 2

		        echo ${LINKS[*]} >> $POSTFILE
		        TMPSORT=(`cat $POSTFILE | uniq`)
		        echo ${TMPSORT[*]} > $POSTFILE

			fi
		done
fi