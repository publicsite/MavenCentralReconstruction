#!/bin/sh
lineNumber=1;
bracketIndex="0"
cat "$1" | while read line; do
if [ "$(printf "%s" "$line" | grep "^\s*//.*")" = "" ]; then
	if [ "$(printf "%s" "$line" | grep "^.*{")" != "" ]; then
		if [ "$bracketIndex" = "1" ]; then
			printf "%s\t%s-" "$line" "$lineNumber"
		fi
	bracketIndex="$(expr $bracketIndex + 1)"
	elif [ "$(printf "%s" "$line" | grep "^.*}")" != "" ]; then
	#echo $bracketIndex
		if [ "$bracketIndex" = "2" ]; then
			printf "%s\n" "$lineNumber"
		fi
	bracketIndex="$(expr $bracketIndex - 1)"
	fi
fi
	lineNumber="$(expr $lineNumber + 1)"
done