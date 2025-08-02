#!/bin/sh
if [ ! -f "$1.bak" ]; then
	cp -a "$1" "$1.orig"
fi

thePom="$(cat "$1" | sed 's#\r##g' | sed 's#[ \t]##g' | tr -d "\n")"
theProperties="$(printf "%s" "$thePom" | grep -o '<properties>.*</properties>')"

if [ "$1" != "$2" ]; then
	oneArtifactId="$(grep -o "<artifactId>.*</artifactId>" "$1"  | head -n 1 | cut -d '>' -f 2 | cut -d '<' -f 1)"
	sed -i "s#\${artifactId}#${oneArtifactId}#g" "$2"
fi

old_ifs="$IFS"
IFS="<"

count=1
listOfProperties=""
for aproperty in $(printf "$theProperties\n"); do
	if [ "$aproperty" != "" ]; then
		if [ "$(echo $aproperty | cut -c 1-1)" != '!' ] && [ "$(echo $aproperty | cut -c 1-1)" != '/' ] && [ "$aproperty" != "properties>" ]; then
			listOfProperties="$listOfProperties\n$aproperty"
			count="$(expr $count + 1)"
		fi
	fi
done

IFS="$old_ifs"

for i in $(seq $count); do
	toprocess="$(echo "$listOfProperties" | head -n $i | tail -n 1)"
	varname="$(echo $toprocess | cut -d '>' -f 1)"
	varvalue="$(echo $toprocess | cut -d '>' -f 2)"
	sed -i "s#\${${varname}}#${varvalue}#g" "$2"
	listOfProperties="$(echo "$listOfProperties" | sed "s#\${${varname}}#${varvalue}#g")"
done
