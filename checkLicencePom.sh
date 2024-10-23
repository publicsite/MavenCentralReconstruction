#!/bin/sh
theXML="$(cat "$1" | sed 's#\r##g' | sed 's#[\t]##g' | tr -d "\n")"
theXMLnoBuild="$(printf "%s" "${theXML}" | sed "s#<build>.*</build>##g")"
licencestring="$(printf "%s" "$theXMLnoBuild" | grep -o '<license>.*</license>')"
if [ "$licencestring" = "" ]; then
	echo "NOTSPECIFIED"
	exit
fi
for alicence in "$licencestring"; do
old_IFS="$IFS"
IFS='/'
for aname in "$(printf "%s" "$alicence")"; do
aname="$(echo $aname | grep -o '<name>.*' | cut -d '>' -f 2 | cut -d '<' -f 1)"
	if [ "$aname" != "" ]; then
		if [ "$(./checkLicence.sh "$aname")" = "" ]; then
			#if licence(s) not on fsf or osi list or public domain
			echo "BAD"
			exit
		fi
	fi
done
IFS="$old_IFS"
done

#if licence(s) are OK
echo "GOOD"